class ProcessTelegramMessageJob < ApplicationJob
  queue_as :default
  require 'net/http'
  require 'json'
  require 'logger'
  SPECIAL_COMMANDS = ['/thinking', '/model', '/prompt', '/persona', '/logs', '/clear', '/relationship', '/help', '/commands', '/memory', '/global_prompt'].freeze
  
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
    # Find the active chat for this telegram chat ID
    chat = Chat.find_or_create_by_telegram(telegram_chat_id)
    Rails.logger.debug("Found chat: #{chat.id} for telegram ID: #{telegram_chat_id}, active: #{chat.active}")

    # Check if this is a command
    if telegram_message.start_with?('/')
      handle_command(telegram_message, telegram_chat_id, chat)
        return
      end

    # Create a new message in the database
    if message_id.present?
      # If we have a message_id, find and update
      message = Message.find_by(telegram_message_id: message_id)
      if message
        message.update(content: telegram_message)
      else
        message = Message.create!(
          chat: chat,
          role: 'user',
          content: telegram_message,
          telegram_chat_id: telegram_chat_id,
          telegram_message_id: message_id
        )
      end
    else
      # Otherwise create a new message
      message = Message.create!(
        chat: chat,
        role: 'user',
        content: telegram_message,
        telegram_chat_id: telegram_chat_id
      )
      end

      # Get chat settings
    settings = ChatSetting.for_chat(chat.id)
    
    # Record interaction with persona for relationship tracking
    if settings.persona
      Rails.logger.debug("Recording interaction with persona: #{settings.persona.name}")
      settings.persona.record_interaction(chat, message)
    end

    # Get the AI's response to this message
    service = OllamaService.new
    model = settings.model || OllamaService::DEFAULT_MODEL

    # Build the prompt using our service
    prompt_builder = PromptBuilderService.new(message)
    messages = prompt_builder.build

    # Log the messages being sent to Ollama
    Rails.logger.debug("Sending to Ollama model #{model}:")
    messages.each do |msg|
      Rails.logger.debug("  #{msg[:role]}: #{msg[:content].truncate(100)}")
    end

    # Generate the AI response
    response = service.chat(
      messages: messages,
      model: model,
      stream: false
    )

    # Check if response is valid
    if response.nil?
      Rails.logger.error("Failed to get a response from Ollama: nil response")
      send_telegram_message(telegram_chat_id, "Sorry, I wasn't able to generate a response. Please try again.")
      return
    end

    # Extract message content based on the response structure
    content = nil
    
    if response.is_a?(Hash)
      if response["message"] && response["message"]["content"]
        # New API format
        content = response["message"]["content"]
      elsif response[:message] && response[:message][:content]
        # Symbolized keys format
        content = response[:message][:content]
      elsif response["response"]
        # Old API format with direct response
        content = response["response"]
      end
    end
    
    # If we couldn't extract content, log and return error
    if content.nil? || content.strip.empty?
      Rails.logger.error("Failed to extract content from Ollama response: #{response.inspect}")
      send_telegram_message(telegram_chat_id, "Sorry, I wasn't able to generate a response. Please try again.")
      return
    end

    # Store the AI's response in the database
    ai_message = Message.create!(
      chat: chat,
      role: 'assistant',
      content: content,
      telegram_chat_id: telegram_chat_id
    )

    # Send the AI's response back to Telegram
    send_telegram_message(telegram_chat_id, content)
    
    # Schedule memory extraction
    ExtractMemoryJob.perform_later(chat.id)
    
    # Record this interaction with the AI for relationship tracking
    if settings.persona
      Rails.logger.debug("Recording AI response interaction with persona: #{settings.persona.name}")
      settings.persona.record_interaction(chat, ai_message)
    end
  end

  private

  def special_command?(message)
    SPECIAL_COMMANDS.any? { |cmd| message.strip.start_with?(cmd) }
  end

  def handle_command(message, telegram_chat_id, chat)
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
    when '/relationship'
      handle_relationship_command(telegram_chat_id, chat)
    when '/memory'
      handle_memory_command(telegram_chat_id, chat)
    when '/global_prompt'
      handle_global_prompt_command(rest, telegram_chat_id, chat)
    when '/help', '/commands'
      handle_help_command(telegram_chat_id, chat)
    else
      send_telegram_message(telegram_chat_id, "Unknown command: #{command}. Use /help to see available commands.")
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
      persona = settings.persona || Persona.default
      current_prompt = settings.prompt.presence || persona.full_prompt
      message = if settings.prompt.present?
        "Current custom prompt: #{current_prompt}\n\n(Using custom prompt instead of #{persona.name}'s default prompt)"
      else
        "Current prompt (from #{persona.name} persona):\n#{current_prompt}"
      end
      send_telegram_message(telegram_chat_id, message)
    else
      # Update prompt setting
      settings = ChatSetting.for_chat(chat.id)
      settings.update(prompt: prompt_text)
      send_telegram_message(telegram_chat_id, "Custom prompt updated. Use '/prompt' without text to see current prompt, or '/persona' to switch personas.")
    end
  end

  def handle_persona_command(persona_name, telegram_chat_id, chat)
    if persona_name.blank?
      # Display available personas
      personas = Persona.active.pluck(:name).join(", ")
      settings = ChatSetting.for_chat(chat.id)
      current_persona = settings.persona&.name || "none"
      send_telegram_message(telegram_chat_id, "Available personas: #{personas}\nCurrent persona: #{current_persona}\nUse '/persona [name]' to switch.")
      return
    end

    # Find the persona
    persona = Persona.active.find_by("LOWER(name) = ?", persona_name.downcase)
    
    if persona.nil?
      send_telegram_message(telegram_chat_id, "Persona '#{persona_name}' not found. Use '/persona' to see available personas.")
      return
    end

    # Create a new active chat
    old_chat = chat
    old_chat.update(active: false)
    new_chat = Chat.create!(telegram_id: telegram_chat_id, active: true)
    
    # Update chat settings with new persona
    settings = ChatSetting.for_chat(new_chat.id)
    settings.update(persona_id: persona.id)
    
    # Add a system message recording the persona change
    Message.create!(
      chat: new_chat,
      role: 'system',
      content: "Conversation started with '#{persona.name}' persona: #{persona.default_prompt}",
      telegram_chat_id: telegram_chat_id
    )
    
    send_telegram_message(telegram_chat_id, "Switched to '#{persona.name}' persona. A new conversation has been started.\n\nPersonality: #{persona.personality_traits.join(', ')}.")
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
    
    # Create a system message in the new chat to represent the clear action
    Message.create!(
      chat: new_chat,
      role: 'system',
      content: 'Chat history was cleared. Starting a new conversation.'
    )
    
    send_telegram_message(telegram_chat_id, "Chat history cleared! Starting a new conversation. 🔄")
    rescue => e
    Rails.logger.error("Failed to clear chat: #{e.message}")
    send_telegram_message(telegram_chat_id, "Sorry, there was an error clearing the chat. Please try again.")
  end

  def handle_relationship_command(telegram_chat_id, chat)
    settings = ChatSetting.for_chat(chat.id)
    persona = settings.persona || Persona.default
    
    if !persona
      send_telegram_message(telegram_chat_id, "No active persona found for this chat.")
      return
    end
    
    # Get relationship data for current chat
    data = persona.relationship_data_for(chat)
    
    stage = data['stage'] || 'stranger'
    interaction_count = data['interaction_count'] || 0
    intimacy_score = data['intimacy_score'] || 0
    attachment_style = data['attachment_style'] || 'secure'
    last_interaction = data['last_interaction'] ? Time.parse(data['last_interaction']).strftime('%Y-%m-%d %H:%M:%S') : 'Never'
    
    message = <<~MSG
      🌟 *Relationship with #{persona.name}* 🌟
      
      📈 *Status*: #{stage.capitalize}
      💬 Interactions: #{interaction_count}
      ❤️ Intimacy score: #{intimacy_score.round(1)}/100
      🔄 Attachment style: #{attachment_style.capitalize}
      🕒 Last interaction: #{last_interaction}
      
      #{relationship_stage_description(stage)}
    MSG
    
    send_telegram_message(telegram_chat_id, message)
  end
  
  def relationship_stage_description(stage)
    case stage
    when 'stranger'
      "You're still getting to know each other. The relationship is in its early stages."
    when 'acquaintance'
      "You've had several conversations and are developing familiarity."
    when 'friend'
      "You've established a comfortable rapport with shared context and understanding."
    when 'close'
      "You've developed a strong connection with mutual trust and openness."
    when 'intimate'
      "You share a deep bond with significant emotional investment and understanding."
    else
      "Your relationship is evolving in unique ways."
    end
  end

  def handle_memory_command(telegram_chat_id, chat)
    # Get all memories for this chat - don't order by importance_score initially
    memories = MemoryFact.where(chat_id: chat.id)
    
    if memories.empty?
      send_telegram_message(telegram_chat_id, "You don't have any memories stored yet. Continue chatting to create memories!")
      return
    end
    
    # Get chat settings and persona
    settings = ChatSetting.for_chat(chat.id)
    persona = settings.persona&.name || "AI"
    
    # Prepare the memory profile
    memory_profile = "🧠 *Memory Profile* 🧠\n\n"
    memory_profile += "Memories stored for your conversation with #{persona}:\n\n"
    
    # Add important memories section
    important_memories = memories.where("importance_score >= ?", 7).order(importance_score: :desc).limit(5)
    if important_memories.any?
      memory_profile += "*Key Memories:*\n"
      important_memories.each do |memory|
        emoji = emotion_to_emoji(memory.emotion)
        memory_profile += "#{emoji} #{memory.summary} (#{memory.topic}, importance: #{memory.importance_score}/10)\n"
      end
      memory_profile += "\n"
    end
    
    # Add recent memories section
    recent_memories = memories.order(extracted_at: :desc).limit(5)
    if recent_memories.any?
      memory_profile += "*Recent Memories:*\n"
      recent_memories.each do |memory|
        emoji = emotion_to_emoji(memory.emotion)
        memory_profile += "#{emoji} #{memory.summary} (#{memory.topic}, importance: #{memory.importance_score}/10)\n"
      end
      memory_profile += "\n"
    end
    
    # Add topic breakdown - avoid SQL ORDER BY by sorting in Ruby
    topics = memories.group(:topic).count.sort_by { |_, count| -count }.take(5)
    if topics.any?
      memory_profile += "*Topics You've Discussed:*\n"
      topics.each do |topic, count|
        topic_emoji = topic_to_emoji(topic)
        memory_profile += "#{topic_emoji} #{topic}: #{count} memories\n"
      end
      memory_profile += "\n"
    end
    
    # Add emotion breakdown - avoid SQL ORDER BY by sorting in Ruby
    emotions = memories.group(:emotion).count.sort_by { |_, count| -count }.take(5)
    if emotions.any?
      memory_profile += "*Emotional Profile:*\n"
      emotions.each do |emotion, count|
        emoji = emotion_to_emoji(emotion)
        memory_profile += "#{emoji} #{emotion.capitalize}: #{count} memories\n"
      end
      memory_profile += "\n"
    end
    
    # For average, use a specific query to avoid SQL errors
    avg_importance = memories.average(:importance_score).to_f.round(1)
    
    # Add total count and summary
    memory_profile += "Total memories: #{memories.count}\n"
    memory_profile += "Average importance: #{avg_importance}/10\n"
    
    # If the message is too long for Telegram, truncate it
    if memory_profile.length > 4000
      memory_profile = memory_profile[0..3995] + "..."
    end
    
    send_telegram_message(telegram_chat_id, memory_profile)
  end

  def emotion_to_emoji(emotion)
    case emotion.to_s.downcase
    when 'happy', 'joy', 'excited', 'pleased'
      "😊"
    when 'sad', 'unhappy', 'depressed'
      "😔"
    when 'angry', 'upset', 'frustrated'
      "😠"
    when 'afraid', 'scared', 'anxious', 'nervous'
      "😨"
    when 'surprised', 'shocked', 'amazed'
      "😮"
    when 'love', 'affection', 'caring'
      "❤️"
    when 'nostalgic', 'reminiscing'
      "🕰️"
    when 'proud', 'accomplished'
      "🏆"
    when 'curious', 'interested'
      "🤔"
    else
      "📝"
    end
  end
  
  def topic_to_emoji(topic)
    case topic.to_s.downcase
    when 'work', 'career', 'job'
      "💼"
    when 'family', 'relatives'
      "👪"
    when 'hobby', 'hobbies', 'interest'
      "🎨"
    when 'travel', 'vacation', 'trip'
      "✈️"
    when 'food', 'cooking', 'recipe'
      "🍲"
    when 'music', 'song'
      "🎵"
    when 'movie', 'film', 'tv', 'show'
      "🎬"
    when 'book', 'reading'
      "📚"
    when 'tech', 'technology', 'computer'
      "💻"
    when 'health', 'fitness', 'exercise'
      "💪"
    when 'education', 'learning', 'school'
      "🎓"
    when 'pet', 'animal'
      "🐾"
    when 'finance', 'money', 'investment'
      "💰"
    when 'relationship', 'dating', 'romance'
      "❤️"
    when 'friend', 'friendship'
      "🤝"
    else
      "🔍"
    end
  end

  def handle_global_prompt_command(prompt_text, telegram_chat_id, chat)
    if prompt_text.blank?
      # Display current global prompt
      current_prompt = Setting.global_prompt
      send_telegram_message(telegram_chat_id, "Current global prompt:\n\n#{current_prompt}\n\nThis prompt is prepended to all persona prompts.")
    else
      # Update global prompt
      Setting.global_prompt = prompt_text
      send_telegram_message(telegram_chat_id, "Global prompt updated. This will affect all conversations with all personas.")
    end
  end

  def handle_help_command(telegram_chat_id, chat)
    settings = ChatSetting.for_chat(chat.id)
    persona = settings.persona&.name || "AI"
    
    help_text = <<~HELP
      🤖 *Available Commands* 🤖
      
      /help or /commands - Show this help message
      /model - View current model (e.g., mistral-small)
      /model [name] - Change the model
      /prompt - View current system prompt
      /prompt [text] - Set a custom system prompt
      /persona - View available personas
      /persona [name] - Switch to a different persona
      /relationship - View your relationship with #{persona}
      /memory - View your complete memory profile
      /global_prompt - View shared prompt for all personas
      /global_prompt [text] - Set shared prompt for all personas
      /clear - Clear chat history and start fresh
      /logs prompt - View last prompt sent
      /logs response - View last AI response
      /logs error - View recent errors
      
      You're currently using the #{persona} persona with the #{settings.model || OllamaService::DEFAULT_MODEL} model.
    HELP
    
    send_telegram_message(telegram_chat_id, help_text)
  end
end 