class ProcessTelegramMessageJob < ApplicationJob
  queue_as :default
  require 'net/http'
  require 'json'
  require 'logger'

  OLLAMA_URL = 'http://127.0.0.1:11434/api/chat'
  
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

      # Call Ollama API with message content and the message object
      response_text = call_ollama(message.content, message)

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

      # Send response
      client.api.send_message(
        chat_id: message.telegram_chat_id,
        text: response_text
      )

      # Create response message in database
      Message.create!(
        content: response_text,
        role: 'gfbot',
        telegram_chat_id: message.telegram_chat_id,
        chat: message.chat,
        responded: true,
        processed_at: Time.current
      )

      # Mark original message as responded
      message.mark_as_responded!
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

  def call_ollama(prompt, message)
    # Get chat settings for model
    settings = ChatSetting.for_chat(message.chat_id)
    
    # Get the last few messages from the chat for context, excluding the current message
    previous_messages = message.chat.messages
                              .where('created_at < ?', message.created_at)
                              .order(created_at: :desc)
                              .limit(20)
                              .reverse

    # Build the messages array in structured format
    messages = [
      {
        "role": "system",
        "content": settings.prompt.presence || "You are a helpful and friendly AI assistant who keeps responses concise and engaging. " \
                  "You aim to be helpful while maintaining a friendly tone. " \
                  "Use emojis occasionally but not excessively. " \
                  "Keep responses brief and to the point."
      }
    ]

    # Add previous messages to the conversation
    previous_messages.each do |msg|
      messages << {
        "role": msg.role == 'user' ? 'user' : 'system',
        "content": msg.content
      }
    end

    # Add the current user message
    messages << {
      "role": "user",
      "content": prompt
    }

    # Log the messages before sending
    self.class.prompt_logger.info(JSON.pretty_generate(messages))

    uri = URI(OLLAMA_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 120  # Increase timeout to 2 minutes
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    
    payload = {
      model: settings.model,
      messages: messages,
      stream: false  # Disable streaming to get a single response
    }
    
    request.body = payload.to_json

    # Log what we're about to send
    Rails.logger.info("Sending request to Ollama: #{request.body}")

    begin
      response = http.request(request)
      
      # Log response details
      Rails.logger.info("Ollama response code: #{response.code}")
      Rails.logger.info("Ollama response headers: #{response.to_hash.inspect}")
      Rails.logger.info("Ollama raw response body: #{response.body.inspect}")
      
      unless response.is_a?(Net::HTTPSuccess)
        raise "Ollama API returned non-200 status: #{response.code} - #{response.body}"
      end

      begin
        parsed_response = JSON.parse(response.body)
      rescue JSON::ParserError => e
        # If we got a streaming response despite asking for non-streaming,
        # try to parse the last complete JSON object
        if response.body.include?('{"model":"llama3"')
          json_objects = response.body.split("\n").select { |line| line.start_with?('{"model":"llama3"') }
          last_response = JSON.parse(json_objects.last)
          parsed_response = last_response
        else
          Rails.logger.error("Failed to parse Ollama response: #{e.message}")
          Rails.logger.error("Raw response was: #{response.body.inspect}")
          raise "Invalid JSON response from Ollama: #{e.message}"
        end
      end

      # Extract the response text from either format
      response_text = if parsed_response['response']
        parsed_response['response']
      elsif parsed_response['message'] && parsed_response['message']['content']
        parsed_response['message']['content']
      else
        raise "Unexpected response format: #{parsed_response.inspect}"
      end

      # Handle empty or invalid response
      if response_text.nil? || response_text.strip.empty?
        error_msg = "Empty response from Ollama: #{parsed_response.inspect}"
        Rails.logger.error(error_msg)
        raise error_msg
      end
      
      # Log just the response text in a readable format
      self.class.ollama_logger.info(response_text)
      
      response_text.strip
    rescue => e
      Rails.logger.error("Error in call_ollama: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise
    end
  end
end 