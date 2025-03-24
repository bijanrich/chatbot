class ProcessTelegramMessageJob < ApplicationJob
  queue_as :default
  require 'net/http'
  require 'json'
  require 'logger'

  def self.ollama_logger
    @@ollama_logger ||= Logger.new(Rails.root.join('log', 'ollama_responses.log')).tap do |logger|
      logger.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime}:\n#{msg}\n\n"
      end
    end
  end

  def self.prompt_logger
    @@prompt_logger ||= Logger.new(Rails.root.join('log', 'ollama_prompts.log')).tap do |logger|
      logger.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime}:\n#{msg}\n\n"
      end
    end
  end

  def perform(message_id)
    message = Message.find(message_id)
    return if message.responded?

    # Initialize Telegram bot client
    client = Telegram::Bot::Client.new(ENV['TELEGRAM_BOT_TOKEN'])

    begin
      # Handle /thinking command
      if message.content.strip == '/thinking'
        handle_thinking_command(message, client)
        return
      end

      # Handle /model command
      if message.content.strip.start_with?('/model')
        handle_model_command(message, client)
        return
      end

      # Handle /prompt command
      if message.content.strip.start_with?('/prompt')
        handle_prompt_command(message, client)
        return
      end

      # Get chat settings
      settings = ChatSetting.for_chat(message.chat_id)

      # Build message array using PromptBuilderService
      messages = PromptBuilderService.new(message).build
      
      # Log the messages before sending
      self.class.prompt_logger.info(JSON.pretty_generate(messages))

      # Call Ollama API using the OllamaService
      response_text = OllamaService.chat(
        messages: messages,
        model: settings.model
      )

      # Ensure we have a valid response
      if response_text.nil? || response_text.strip.empty?
        raise "Received empty response from Ollama"
      end

      # If thinking is disabled, strip out the thinking section
      unless settings.show_thinking
        response_text = response_text.gsub(/<think>.*?<\/think>/m, '').strip
      end

      # Ensure we still have content after stripping thinking section
      if response_text.strip.empty?
        raise "Response is empty after processing"
      end
      
      # Log just the response text in a readable format
      self.class.ollama_logger.info(response_text)

      # Send response
      client.api.send_message(
        chat_id: message.telegram_chat_id,
        text: response_text
      )

      # Create response message in database
      assistant_message = Message.create!(
        content: response_text,
        role: 'gfbot',
        telegram_chat_id: message.telegram_chat_id,
        chat: message.chat,
        responded: true,
        processed_at: Time.current
      )

      # Mark original message as responded
      message.mark_as_responded!
      
      # Queue memory extraction only for user messages
      ExtractMemoryJob.perform_later(message.id) if message.role == 'user'
      
    rescue => e
      Rails.logger.error "Error processing Telegram message #{message_id}: #{e.message}\n#{e.backtrace.join("\n")}"
      
      # Send error message to user
      begin
        client.api.send_message(
          chat_id: message.telegram_chat_id,
          text: "Error: #{e.message}"
        )
      rescue => telegram_error
        Rails.logger.error "Failed to send error message: #{telegram_error.message}"
      end

      raise # Re-raise the error to trigger Sidekiq retry
    end
  end

  private

  def handle_thinking_command(message, client)
    settings = ChatSetting.for_chat(message.chat_id)
    settings.toggle_thinking!

    status = settings.show_thinking ? "enabled" : "disabled"
    
    client.api.send_message(
      chat_id: message.telegram_chat_id,
      text: "🤔 Thinking mode #{status}! #{settings.show_thinking ? 'You will now see my thought process.' : 'Thought process will be hidden.'}"
    )

    # Mark as responded
    message.mark_as_responded!
  end

  def handle_model_command(message, client)
    model_name = message.content.strip.split(' ', 2)[1]&.strip

    unless model_name
      client.api.send_message(
        chat_id: message.telegram_chat_id,
        text: "Please specify a model name. Example: /model llama3"
      )
      message.mark_as_responded!
      return
    end

    settings = ChatSetting.for_chat(message.chat_id)
    settings.update(model: model_name)

    client.api.send_message(
      chat_id: message.telegram_chat_id,
      text: "🤖 Model changed to: #{model_name}"
    )

    message.mark_as_responded!
  end

  def handle_prompt_command(message, client)
    prompt_text = message.content.strip.split(' ', 2)[1]&.strip

    unless prompt_text
      client.api.send_message(
        chat_id: message.telegram_chat_id,
        text: "Please specify a prompt. Example: /prompt You are a helpful and friendly AI assistant"
      )
      message.mark_as_responded!
      return
    end

    settings = ChatSetting.for_chat(message.chat_id)
    settings.update(prompt: prompt_text)

    client.api.send_message(
      chat_id: message.telegram_chat_id,
      text: "✨ System prompt updated! I'll use this personality from now on."
    )

    message.mark_as_responded!
  end
end 