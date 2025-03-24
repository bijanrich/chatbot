class ProcessTelegramMessageJob < ApplicationJob
  queue_as :default
  require 'net/http'
  require 'json'
  require 'logger'
  SPECIAL_COMMANDS = ['/thinking', '/model', '/prompt', '/persona', '/logs', '/clear'].freeze
  
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
    chat = Chat.find_or_create_by_telegram(telegram_chat_id)
    
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
    model = settings.model.presence || OllamaService::DEFAULT_MODEL

    begin
      # Build prompt with context using PromptBuilderService
      messages = PromptBuilderService.new(message).build
      
      # No need to log here since OllamaService will now handle detailed logging
      
      # Call Ollama API to get a response
      response_text = OllamaService.generate_response(messages, model)
      
      if response_text.blank?
        Rails.logger.error("Received empty response from Ollama API")
        send_telegram_message(telegram_chat_id, "I apologize, but I wasn't able to generate a response. Please try again.")
        message.update(responded: true)
        return
      end

      # No need to log the response here since OllamaService now handles it

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
    when '/persona'
      handle_persona_command(rest, telegram_chat_id, chat)
    when '/logs'
      handle_logs_command(rest, telegram_chat_id, chat)
    when '/clear'
      handle_clear_command(telegram_chat_id, chat)
    end
  end

  def handle_model_command(model_name, telegram_chat_id, chat)
    if model_name.blank?
      # Display current model
      settings = ChatSetting.for_chat(chat.id)
      current_model = settings.model.presence || OllamaService::DEFAULT_MODEL
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
      current_prompt = settings.prompt.presence || PromptBuilderService.new(nil).send(:default_system_prompt)
      send_telegram_message(telegram_chat_id, "Current prompt: #{current_prompt}")
    else
      # Update prompt setting
      settings = ChatSetting.for_chat(chat.id)
    settings.update(prompt: prompt_text)
      send_telegram_message(telegram_chat_id, "System prompt updated.")
    end
  end

  def handle_persona_command(persona_name, telegram_chat_id, chat)
    settings = ChatSetting.for_chat(chat.id)
    
    if persona_name.blank?
      # Display current persona and list available ones
      current_persona = settings.persona&.name || 'default'
      available_personas = Persona.all.map(&:name).join(", ")
      message = "Current persona: #{current_persona}\n\nAvailable personas: #{available_personas}"
      send_telegram_message(telegram_chat_id, message)
    else
      # Try to set the new persona
      persona = Persona.find_by(name: persona_name.strip.downcase)
      if persona
        # First, mark the old chat as inactive
        chat.update!(active: false)
        
        # Then create a new chat for the new persona
        new_chat = Chat.create!(telegram_id: telegram_chat_id)
        
        # Create settings for the new chat with the selected persona
        ChatSetting.create!(
          chat: new_chat,
          persona: persona,
          model: settings.model # Preserve the current model setting
        )
        
        welcome_message = "Switched to persona: #{persona.name}\n\n" \
                         "Starting fresh chat with #{persona.name}! 🔄\n" \
                         "#{persona.description}"
        
        send_telegram_message(telegram_chat_id, welcome_message)
      else
        send_telegram_message(telegram_chat_id, "Persona '#{persona_name}' not found. Use /persona to see available personas.")
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to switch persona: #{e.message}")
    send_telegram_message(telegram_chat_id, "Sorry, there was an error switching personas. Please try again.")
  end

  def handle_logs_command(log_type, telegram_chat_id, chat)
    log_type = log_type&.strip&.downcase || 'help'
    
    case log_type
    when 'help'
      help_text = "Log commands available:\n" \
                  "/logs prompt - View last prompt sent to Ollama\n" \
                  "/logs response - View last response from Ollama\n" \
                  "/logs error - View last error log"
      send_telegram_message(telegram_chat_id, help_text)
    when 'prompt'
      log_file = Rails.root.join('log', 'ollama_prompts.log')
      send_recent_log(telegram_chat_id, log_file, 'No prompt logs found')
    when 'response'
      log_file = Rails.root.join('log', 'ollama_responses.log')
      send_recent_log(telegram_chat_id, log_file, 'No response logs found')
    when 'error'
      log_file = Rails.root.join('log', 'development.log')
      # Extract only error logs from the development log
      error_logs = extract_errors_from_log(log_file)
      if error_logs.present?
        send_telegram_message(telegram_chat_id, "Recent errors:\n\n#{error_logs}")
      else
        send_telegram_message(telegram_chat_id, "No recent errors found")
      end
    else
      send_telegram_message(telegram_chat_id, "Unknown log type. Use '/logs help' for available options.")
    end
  end

  def send_recent_log(telegram_chat_id, log_file, empty_message)
    if File.exist?(log_file)
      # Get the last log entry (entries are separated by double newlines)
      logs = File.read(log_file)
      log_entries = logs.split("\n\n")
      
      if log_entries.any?
        # Get the last entry and limit its size for Telegram
        last_entry = log_entries.last(3).join("\n\n")
        # Truncate if too long for Telegram
        if last_entry.length > 4000
          last_entry = last_entry[0..3997] + "..."
        end
        send_telegram_message(telegram_chat_id, last_entry)
      else
        send_telegram_message(telegram_chat_id, empty_message)
      end
    else
      send_telegram_message(telegram_chat_id, "Log file not found")
    end
  end

  def extract_errors_from_log(log_file)
    return "Log file not found" unless File.exist?(log_file)
    
    # Use tail to get the last 500 lines of the log file
    log_content = `tail -n 500 #{log_file}`
    
    # Extract lines containing "ERROR" or "Error"
    error_lines = log_content.lines.select { |line| line.include?("ERROR") || line.include?("Error") }
    
    # Get the last 10 error messages
    recent_errors = error_lines.last(10)
    
    if recent_errors.any?
      recent_errors.join
    else
      "No recent errors found"
    end
  end

  def send_telegram_message(chat_id, text)
    return if text.blank?

    uri = URI("https://api.telegram.org/bot#{ENV['TELEGRAM_BOT_TOKEN']}/sendMessage")
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

  def handle_clear_command(telegram_chat_id, chat)
    # First, mark the old chat as inactive
    chat.update!(active: false)
    
    # Create a new chat with the same telegram_id
    new_chat = Chat.create!(telegram_id: telegram_chat_id)
    
    # Copy settings from the old chat to preserve model, persona, etc.
    old_settings = ChatSetting.for_chat(chat.id)
    ChatSetting.create!(
      chat: new_chat,
      model: old_settings.model,
      persona: old_settings.persona,
      show_thinking: old_settings.show_thinking
    )
    
    send_telegram_message(telegram_chat_id, "Chat history cleared! Starting a new conversation. 🔄")
  rescue => e
    Rails.logger.error("Failed to clear chat: #{e.message}")
    send_telegram_message(telegram_chat_id, "Sorry, there was an error clearing the chat. Please try again.")
  end
end 