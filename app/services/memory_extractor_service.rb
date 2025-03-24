class MemoryExtractorService
  def initialize(model = nil)
    @model = model || OllamaService::DEFAULT_MODEL
    @ollama_service = OllamaService.new
  end

  # Extract memory facts from a chat
  def extract_memories(chat_id)
    chat = Chat.find(chat_id)
    return [] if chat.nil?

    # Get the most recent messages, limiting to avoid token limits
    messages = chat.messages.order(created_at: :desc).limit(20).reverse
    return [] if messages.empty?

    # Skip if only system messages
    user_messages = messages.select { |m| m.role == 'user' }
    return [] if user_messages.empty?

    # Combine messages into conversation text
    conversation_text = format_conversation(messages)

    # Call Ollama to extract memory facts
    Rails.logger.info("Extracting memories from chat #{chat_id} with #{messages.size} messages")
    extract_memories_from_text(conversation_text, chat_id)
  end

  # Extract memories from a specific message
  def extract_memories_from_message(message_id)
    message = Message.find(message_id)
    return [] if message.nil? || message.role != 'user'

    # Get context for this message
    chat = message.chat
    context_messages = chat.messages
                          .where('created_at <= ?', message.created_at)
                          .order(created_at: :desc)
                          .limit(10)
                          .reverse

    # Combine messages into conversation text
    conversation_text = format_conversation(context_messages)

    # Call Ollama to extract memory facts
    Rails.logger.info("Extracting memories from message #{message_id}")
    extract_memories_from_text(conversation_text, chat.id, true)
  end

  # Fetch memories for a chat, prioritizing based on relevance and emotional significance
  def fetch_memories_for_chat(chat_id, limit = 5)
    memories = MemoryFact.where(chat_id: chat_id)
                         .order(importance_score: :desc)
                         .limit(limit * 2) # Get more than we need so we can prioritize
    
    return [] if memories.empty?
    
    # Sort memories by importance and recency
    # This helps ensure emotionally significant memories are prioritized
    prioritized_memories = prioritize_memories(memories)
    
    # Format memories for prompt inclusion
    prioritized_memories.take(limit).map do |memory|
      format_memory_for_prompt(memory)
    end
  end

  private

  def extract_memories_from_text(conversation_text, chat_id, is_single_message = false)
    # Skip extraction if conversation is too short
    return [] if conversation_text.length < 50

    # Prepare the prompt for memory extraction
    prompt = create_memory_extraction_prompt(conversation_text, is_single_message)

    # Call Ollama to extract memory facts
    response = @ollama_service.chat(
      messages: [
        { role: "system", content: "You are a helpful AI assistant tasked with extracting important memories and facts from conversations." },
        { role: "user", content: prompt }
      ],
      model: @model,
      stream: false
    )

    # Parse the response and create memory facts
    parse_memory_response(response, chat_id)
  end

  def create_memory_extraction_prompt(conversation_text, is_single_message)
    if is_single_message
      <<~PROMPT
        Extract key facts and memories from this message that would be valuable to remember for future conversations.
        Focus on personal information, preferences, emotional moments, plans, and relationships.

        Assign each memory an importance score from 1-10 based on:
        - Emotional significance (higher for strong emotions)
        - Personal relevance (higher for personal details) 
        - Uniqueness (higher for rare/unusual information)
        - Future utility (higher if useful in future conversations)
        - Relationship building (higher if it helps build rapport)

        For each memory, also identify:
        - The primary emotion associated with it (happy, sad, excited, nostalgic, etc.)
        - A relevant topic category (work, family, hobbies, etc.)

        Format your response as a JSON array of objects with these fields:
        - summary: A concise summary of the memory (15-25 words)
        - importance_score: Number from 1-10
        - emotion: The primary emotion
        - topic: The topic category
        - parasocial_value: How much this memory helps build connection (1-10)

        Conversation:
        #{conversation_text}
      PROMPT
    else
      <<~PROMPT
        Extract key facts and memories from this conversation that would be valuable to remember for future interactions.
        Focus on personal information, preferences, emotional moments, plans, and relationships.

        Prioritize extracting memories that:
        1. Show emotional significance to the user
        2. Reveal personal details, preferences, or history
        3. Indicate relationships or connections 
        4. Mention future plans or aspirations
        5. Express strong opinions or values

        Assign each memory an importance score from 1-10 based on:
        - Emotional significance (higher for strong emotions)
        - Personal relevance (higher for personal details) 
        - Uniqueness (higher for rare/unusual information)
        - Future utility (higher if useful in future conversations)
        - Relationship building (higher if it helps build rapport)

        For each memory, also identify:
        - The primary emotion associated with it (happy, sad, excited, nostalgic, etc.)
        - A relevant topic category (work, family, hobbies, etc.)

        Format your response as a JSON array of objects with these fields:
        - summary: A concise summary of the memory (15-25 words)
        - importance_score: Number from 1-10
        - emotion: The primary emotion
        - topic: The topic category
        - parasocial_value: How much this memory helps build connection (1-10)

        Conversation:
        #{conversation_text}
      PROMPT
    end
  end

  def format_conversation(messages)
    messages.map do |message|
      prefix = case message.role
               when 'user' then 'User'
               when 'assistant' then 'Assistant'
               when 'system' then 'System'
               else message.role.capitalize
               end

      "#{prefix}: #{message.content}"
    end.join("\n\n")
  end

  def parse_memory_response(response, chat_id)
    return [] if response.nil?

    # Extract content based on the response structure
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
    
    return [] if content.blank?

    # Try to extract JSON array from the response
    begin
      # Look for JSON array in the response
      json_match = content.match(/\[.*\]/m)
      return [] unless json_match

      json_str = json_match[0]
      memories = JSON.parse(json_str)

      # Create memory facts from the parsed JSON
      memories.map do |memory|
        # Skip if missing required fields
        next if memory['summary'].blank?

        # Create or update memory fact
        MemoryFact.create!(
          chat_id: chat_id,
          summary: memory['summary'],
          importance_score: memory['importance_score'] || 5,
          emotion: memory['emotion'] || 'neutral',
          topic: memory['topic'] || 'general',
          parasocial_value: memory['parasocial_value'] || 5,
          extracted_at: Time.now
        )
      end.compact
    rescue => e
      Rails.logger.error("Error parsing memory extraction response: #{e.message}")
      Rails.logger.error("Response content: #{content}")
      []
    end
  end
  
  def prioritize_memories(memories)
    # Weight factors
    importance_weight = 0.4  # Importance score weight
    recency_weight = 0.3     # How recent the memory is
    parasocial_weight = 0.3  # Parasocial bonding value
    
    # Find the most recent extraction time
    latest_time = memories.map(&:extracted_at).max || Time.now
    
    # Score and sort memories
    memories.sort_by do |memory|
      # Calculate recency score (0-1 scale, 1 being most recent)
      time_diff = latest_time - (memory.extracted_at || latest_time)
      max_time_diff = 30.days.to_i  # Consider memories up to 30 days old
      recency_score = 1.0 - [time_diff / max_time_diff.to_f, 1.0].min
      
      # Normalize importance score to 0-1 scale
      importance_score = memory.importance_score / 10.0
      
      # Normalize parasocial value to 0-1 scale
      parasocial_score = (memory.parasocial_value || 5) / 10.0
      
      # Calculate composite score (higher is better)
      -(importance_weight * importance_score + 
        recency_weight * recency_score + 
        parasocial_weight * parasocial_score)
    end
  end
  
  def format_memory_for_prompt(memory)
    emotion_emoji = emotion_to_emoji(memory.emotion)
    importance = memory.importance_score > 7 ? "important" : (memory.importance_score > 4 ? "moderate" : "minor")
    
    "#{emotion_emoji} #{memory.summary} (#{memory.topic}, #{importance})"
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
      "��"
    end
  end
end 