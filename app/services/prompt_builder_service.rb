class PromptBuilderService
  def initialize(message)
    @message = message
    @chat = message.chat
  end

  def build
    # Get chat settings for model
    settings = ChatSetting.for_chat(@chat.id)
    
    # Get the last few messages from the chat for context, excluding the current message
    previous_messages = @chat.messages
                             .where('created_at < ?', @message.created_at)
                             .order(created_at: :desc)
                             .limit(20)
                             .reverse

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
      messages << {
        "role": msg.role == 'user' ? 'user' : 'assistant',
        "content": msg.content
      }
    end

    # Add the current user message
    messages << {
      "role": "user",
      "content": @message.content
    }
    
    messages
  end

  private
  
  def memory_context
    # Find recent and relevant memories
    memories = MemoryFact.find_recent(@chat.id, limit: 5)
    
    return nil if memories.empty?
    
    # Format memories for inclusion in the prompt
    context = "Here are some relevant facts and memories from our previous conversations:\n\n"
    
    memories.each do |memory|
      importance = case memory.importance_score
                   when 1..3 then "low"
                   when 4..7 then "medium" 
                   else "high"
                   end
                   
      context += "- #{memory.summary} (#{memory.topic}, #{memory.emotion}, importance: #{importance})\n"
    end
    
    context
  end

  def system_prompt(settings)
    settings.prompt.presence || default_system_prompt
  end

  def default_system_prompt
    "You are a helpful and friendly AI assistant who keeps responses concise and engaging. " \
    "You aim to be helpful while maintaining a friendly tone. " \
    "Use emojis occasionally but not excessively. " \
    "Keep responses brief and to the point."
  end
end 