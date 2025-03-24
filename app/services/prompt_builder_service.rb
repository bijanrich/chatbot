class PromptBuilderService
  def initialize(message = nil)
    @message = message
    @chat = message&.chat
  end

  def build
    raise "Message is required for building prompts" if @message.nil?

    # Get chat settings for model
    settings = ChatSetting.for_chat(@chat.id)
    
    # Get the last few messages from the chat for context, excluding the current message
    previous_messages = @chat.messages
                             .where('created_at < ?', @message.created_at)
                             .where(chat_id: @chat.id) # Ensure we only get messages from this specific chat
                             .order(created_at: :desc)
                             .limit(20)
                             .reverse

    # Debug log to verify we're getting the right messages
    Rails.logger.debug("Building prompt for chat #{@chat.id} (telegram_id: #{@chat.telegram_id}, active: #{@chat.active})")
    Rails.logger.debug("Found #{previous_messages.size} previous messages for context")

    # Build the messages array in structured format
    messages = [
      {
        "role": "system",
        "content": system_prompt(settings)
      }
    ]
    
    # Add relevant memories if available
    memory_content = memory_context
    if memory_content.present?
      messages << {
        "role": "system",
        "content": memory_content
      }
    end

    # Add previous messages to the conversation
    previous_messages.each do |msg|
      role = msg.role
      # Skip system messages as they're already included
      next if role == 'system'
      
      messages << {
        "role": role,
        "content": msg.content
      }
    end

    # Add the current message
    messages << {
      "role": @message.role,
      "content": @message.content
    }

    # Return the structured messages for the API
    messages
  end

  private

  def system_prompt(settings)
    # Always use a persona - either the one from settings or the default one
    persona = settings.persona || Persona.default
    Rails.logger.debug("Using persona: #{persona.name} for prompt")
    
    # Use custom prompt if set, otherwise use persona's full prompt with relationship context
    settings.prompt.presence || persona.full_prompt(@chat)
  end

  def memory_context
    return "" if @chat.nil?

    memory_service = MemoryExtractorService.new
    memories = memory_service.fetch_memories_for_chat(@chat.id)
    
    if memories.present?
      "Here are some important memories from previous conversations:\n\n#{memories.join("\n\n")}"
    else
      ""
    end
  end
end 