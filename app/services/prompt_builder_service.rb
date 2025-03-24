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