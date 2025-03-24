class MemoryExtractorService
  def initialize(message)
    @message = message
    @chat = message.chat
  end

  def extract_memory_facts
    # Call Ollama API to extract memories from the message
    response = OllamaService.chat(
      messages: [
        { role: "system", content: memory_extraction_prompt },
        { role: "user", content: @message.content }
      ]
    )

    # Parse the JSON response
    begin
      memory_data = JSON.parse(response)
    rescue JSON::ParserError
      Rails.logger.error("Failed to parse memory extraction response as JSON: #{response}")
      return []
    end
    
    # Create memory facts if any were extracted
    return [] if !memory_data.is_a?(Hash) || !memory_data["memories"].is_a?(Array) || memory_data["memories"].empty?

    memory_data["memories"].map do |memory|
      MemoryFact.create!(
        chat: @chat,
        summary: memory["summary"],
        topic: memory["topic"],
        emotion: memory["emotion"],
        importance_score: memory["importance_score"]
      )
    rescue => e
      Rails.logger.error("Failed to create memory fact: #{e.message}")
      Rails.logger.error("Memory data: #{memory.inspect}")
      nil
    end.compact
  end

  private

  def memory_extraction_prompt
    <<~PROMPT
      You are a memory extraction system. Analyze the message and extract any important facts, preferences, or emotional content that should be remembered for future context.

      You MUST respond with ONLY a JSON object in this exact format (no other text):
      {
        "memories": [
          {
            "summary": "Brief description of the memory",
            "topic": "One of: preference, fact, emotion, relationship, experience",
            "emotion": "positive, negative, or neutral",
            "importance_score": 1-10 integer indicating importance
          }
        ]
      }

      If no memory-worthy content is found, respond with: {"memories": []}

      Focus on extracting:
      - Personal information
      - Strong opinions or preferences
      - Emotional statements
      - Key life events
      - Relationships and social connections
      - Habits and routines
      - Goals and aspirations
    PROMPT
  end
end 