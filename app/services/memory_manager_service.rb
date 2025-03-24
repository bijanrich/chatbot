class MemoryManagerService
  def initialize(user_id)
    @user_id = user_id || 'test-user'
    ensure_user_exists
  end

  # Store a new message and potentially extract facts
  def process_message(message, role)
    # Store in short-term memory
    ShortTermMemory.store_message(@user_id, message, role)

    # If it's an assistant message, try to extract facts
    extract_facts(message) if role == 'assistant'
  end

  # Build context for the next interaction
  def build_context
    {
      recent_messages: ShortTermMemory.format_for_context(@user_id),
      relevant_facts: get_relevant_facts
    }
  end

  private

  def ensure_user_exists
    return if User.exists?(id: @user_id)
    
    # Create a new user if they don't exist
    User.create!(
      id: @user_id.to_s,  # Convert to string for consistency
      name: "Test User",
      email: "test-#{@user_id}@example.com"
    )
  rescue ActiveRecord::RecordInvalid
    # For testing, if email is taken, try with a timestamp
    User.create!(
      id: @user_id.to_s,
      name: "Test User",
      email: "test-#{@user_id}-#{Time.now.to_i}@example.com"
    )
  end

  def extract_facts(message)
    # Skip fact extraction for test messages
    return if @user_id == 'test-user'

    # Use OpenAI to extract facts from the message
    response = OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4",
        messages: [
          {
            role: "system",
            content: "Extract key facts about the user from this message. " \
                    "Return ONLY the facts, one per line. " \
                    "If no clear facts are present, return an empty string."
          },
          {
            role: "user",
            content: message
          }
        ],
        temperature: 0.3
      }
    )

    facts = response.dig("choices", 0, "message", "content").to_s.strip
    
    # Store each fact if any were extracted
    facts.split("\n").each do |fact|
      UserMemory.update_facts(@user_id, fact.strip) unless fact.blank?
    end
  end

  def get_relevant_facts
    # Skip for test messages
    return [] if @user_id == 'test-user'
    
    # Get the last few messages to use as context for retrieving relevant facts
    recent_context = ShortTermMemory.recent_history(@user_id)
      .last(3)
      .map(&:message)
      .join(" ")

    UserMemory.retrieve_relevant_facts(@user_id, recent_context)
  end
end 