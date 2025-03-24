class MemoryExtractorService
  def initialize(chat)
    @chat = chat
  end

  def extract_memory_facts(message)
    return unless message.role == 'user'
    return if message.content.blank?

    # Create a request to extract memories
    prompt = create_memory_extraction_prompt(message.content)
    
    begin
      # Make the request to the Ollama API
      response = OllamaService.chat(
        messages: [{ role: 'user', content: prompt }],
        model: 'llama3'
      )
      
      Rails.logger.info("Memory extraction result: #{response}")
      
      if response.present?
        # Parse the JSON response
        begin
          memories = JSON.parse(response)
          
          if memories.is_a?(Array)
            # Process each memory fact
            memories.each do |memory_data|
              create_memory_fact(message, memory_data)
            end
          else
            Rails.logger.error("Invalid memory extraction format, expected array: #{memories.inspect}")
          end
        rescue JSON::ParserError => e
          Rails.logger.error("Failed to parse memory extraction response: #{e.message}")
          Rails.logger.error("Response was: #{response}")
        end
      end
    rescue => e
      Rails.logger.error("Error in memory extraction: #{e.message}")
    end
  end
  
  private
  
  def create_memory_fact(message, memory_data)
    return unless memory_data.is_a?(Hash)
    
    # Extract fields with fallbacks for missing data
    summary = memory_data['summary'].to_s
    topic = memory_data['topic'].to_s
    emotion = memory_data['emotion'].to_s
    importance_score = memory_data['importance'].to_i
    
    # Ensure importance score is within valid range
    importance_score = [[importance_score, 0].max, 10].min
    
    # Skip if missing required fields
    return if summary.blank? || topic.blank? || emotion.blank?
    
    # Generate embedding for the memory if pgvector is available
    embedding = nil
    
    if pgvector_available?
      begin
        embedding = OllamaService.generate_embedding(summary)
      rescue => e
        Rails.logger.error("Failed to generate embedding for memory: #{e.message}")
      end
    end
    
    # Create the memory fact
    begin
      memory_fact = MemoryFact.create!(
        chat: @chat,
        message_id: message.id,
        summary: summary,
        topic: topic,
        emotion: emotion,
        importance_score: importance_score,
        embedding: embedding
      )
      
      Rails.logger.info("Created memory fact: #{memory_fact.id} - #{memory_fact.summary}")
    rescue => e
      Rails.logger.error("Failed to create memory fact: #{e.message}")
    end
  end
  
  def create_memory_extraction_prompt(content)
    <<~PROMPT
      Extract key memories or facts from the following message. Focus on strong opinions, preferences, personal information, and emotionally significant content.
      
      For each memory, identify:
      1. A concise summary of the memory/fact
      2. The general topic (e.g., food, hobby, work, relationship)
      3. The associated emotion (e.g., happy, sad, excited, nostalgic)
      4. Importance score (1-10) based on how personal or significant this fact seems
      
      Respond with a JSON array of memories in this format:
      [
        {
          "summary": "concise memory description",
          "topic": "general topic",
          "emotion": "primary emotion",
          "importance": importance_score
        }
      ]
      
      If no clear memories are present, return an empty array: []
      
      Message: #{content}
    PROMPT
  end
  
  def pgvector_available?
    ActiveRecord::Base.connection.extension_enabled?('vector')
  rescue
    false
  end
end 