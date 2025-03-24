class ProcessTelegramMessageJob < ApplicationJob
  queue_as :default
  require 'net/http'
  require 'json'
  require 'logger'
  SPECIAL_COMMANDS = ['/thinking', '/model', '/prompt'].freeze

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

  def perform(telegram_message, telegram_chat_id, message_id = nil)
    return if telegram_message.blank? || telegram_chat_id.blank?

    # Get or create the chat for this Telegram chat
    chat = Chat.find_or_create_by(telegram_id: telegram_chat_id)
    
    # Check if this is a message that needs a response (not a special command)
    if special_command?(telegram_message)
      handle_special_command(telegram_message, telegram_chat_id, chat)
      return
    end

    # Create a message for the user's input
    message = if message_id
      # Update existing message
      Message.find(message_id).tap do |msg|
        msg.update(content: telegram_message)
      end
    else
      # Create new message
      Message.create_from_telegram(telegram_chat_id, telegram_message)
    end

    # Get the custom model for this chat or use default
    settings = ChatSetting.for_chat(chat.id)
    model = settings.model.presence || 'llama3'

    begin
      # Build prompt with context using PromptBuilderService
      messages = PromptBuilderService.new(message).build
      
      # Log the messages being sent for debugging
      Rails.logger.info("Sending messages to Ollama: #{messages.inspect}")
      
      # Call Ollama API to get a response
      response_text = OllamaService.generate_response(messages, model)
      
      if response_text.blank?
        Rails.logger.error("Received empty response from Ollama API")
        send_telegram_message(telegram_chat_id, "I apologize, but I wasn't able to generate a response. Please try again.")
        message.update(responded: true)
        return
      end

      # Log the response received
      Rails.logger.info("Response from Ollama: #{response_text}")

      # Send the response back to Telegram
      send_telegram_message(telegram_chat_id, response_text)

      # Create a message for the assistant's response
      assistant_message = Message.create!(
        chat: chat,
        role: 'assistant',
        content: response_text
      )

      # Process message for memory extraction asynchronously (user message only)
      ExtractMemoryJob.perform_later(message.id) if message.role == 'user'

      # Mark the original message as responded
      message.update(responded: true)
    rescue => e
      Rails.logger.error("Error in ProcessTelegramMessageJob: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      # Send error message to Telegram
      send_telegram_message(telegram_chat_id, "I apologize, but I encountered an error while processing your message. Please try again later.")
      # Mark as responded so we don't retry
      message.update(responded: true) if message
    end
  end

  private

  def special_command?(message)
    SPECIAL_COMMANDS.any? { |cmd| message.strip.start_with?(cmd) }
  end

  def handle_special_command(message, telegram_chat_id, chat)
    command, rest = message.split(' ', 2)
    case command
    when '/thinking'
      # Toggle thinking mode - just acknowledge the command
      send_telegram_message(telegram_chat_id, "Thinking mode settings updated.")
    when '/model'
      handle_model_command(rest, telegram_chat_id, chat)
    when '/prompt'
      handle_prompt_command(rest, telegram_chat_id, chat)
    end
  end

  def handle_model_command(model_name, telegram_chat_id, chat)
    if model_name.blank?
      # Display current model
      settings = ChatSetting.for_chat(chat.id)
      current_model = settings.model.presence || 'llama3'
      send_telegram_message(telegram_chat_id, "Current model: #{current_model}")
    else
      # Update model setting
      settings = ChatSetting.for_chat(chat.id)
      settings.update(model: model_name.strip)
      send_telegram_message(telegram_chat_id, "Model updated to: #{model_name.strip}")
    end
  end

  def handle_prompt_command(prompt_text, telegram_chat_id, chat)
    if prompt_text.blank?
      # Display current prompt
      settings = ChatSetting.for_chat(chat.id)
      current_prompt = settings.prompt.presence || "Default system prompt"
      send_telegram_message(telegram_chat_id, "Current prompt: #{current_prompt}")
    else
      # Update prompt setting
      settings = ChatSetting.for_chat(chat.id)
      settings.update(prompt: prompt_text)
      send_telegram_message(telegram_chat_id, "System prompt updated.")
    end
  end

  def send_telegram_message(chat_id, text)
    return if text.blank?

    uri = URI("https://api.telegram.org/bot#{ENV['TELEGRAM_API_TOKEN']}/sendMessage")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = {
      chat_id: chat_id,
      text: text
    }.to_json

    response = http.request(request)
    
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("Failed to send Telegram message: #{response.code} - #{response.message}")
      Rails.logger.error("Response body: #{response.body}")
    end
  end
end 