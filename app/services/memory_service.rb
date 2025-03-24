class MemoryService
  def initialize(chat)
    @chat = chat
  end

  # Create a new memory fact from a message
  def create_memory_from_message(message, importance: 1.0)
    # Generate embedding for the message
    embedding = generate_embedding(message.content)
    
    # Detect topic and emotion
    topic = detect_topic(message.content)
    emotion = detect_emotion(message.content)
    context_type = detect_context_type(message.content)
    
    # Create the memory fact
    MemoryFact.create!(
      chat: @chat,
      summary: message.content,
      topic: topic,
      emotion: emotion,
      context_type: context_type,
      importance_score: importance,
      embedding: embedding,
      metadata: {
        message_id: message.id,
        role: message.role,
        created_at: message.created_at
      }
    )
  end

  # Retrieve relevant memories for the current context
  def retrieve_relevant_memories(current_message, limit: 5)
    return [] if current_message.blank?

    embedding = generate_embedding(current_message)
    
    # Get memories based on vector similarity and importance
    memories = MemoryFact.where(chat: @chat)
      .order(Arel.sql("embedding <-> '#{embedding.join(',')}'"))
      .where('importance_score >= ?', 0.2)
      .limit(limit)
    
    # Update recall stats for retrieved memories
    memories.each do |memory|
      memory.update(
        recall_count: memory.recall_count + 1,
        last_recalled_at: Time.current
      )
    end

    memories
  end

  # Create a conversation summary for a time period
  def create_conversation_summary(start_time, end_time)
    messages = Message.where(chat: @chat)
      .where(created_at: start_time..end_time)
      .order(created_at: :asc)
    
    return if messages.empty?

    # Generate summary text using the messages
    summary_text = generate_summary(messages)
    
    # Detect overall emotion tone
    emotion_tone = analyze_emotion_tone(messages)
    
    # Extract key points
    key_points = extract_key_points(messages)
    
    # Create embedding for the summary
    embedding = generate_embedding(summary_text)
    
    ConversationSummary.create!(
      chat: @chat,
      summary: summary_text,
      emotion_tone: emotion_tone,
      key_points: key_points,
      embedding: embedding,
      start_time: start_time,
      end_time: end_time,
      message_count: messages.count
    )
  end

  # Update relationship state based on interaction
  def update_relationship_state(message)
    state = RelationshipState.find_or_create_by(chat: @chat)
    
    # Update stage if needed
    new_stage = determine_relationship_stage(state.stage, message)
    
    # Update emotional state
    emotional_state = analyze_emotional_state(message)
    
    # Update trust level based on interaction
    trust_delta = calculate_trust_change(message)
    new_trust = [0, [1, state.trust_level.to_f + trust_delta].min].max
    
    # Update flags based on behavior
    flags = update_relationship_flags(state.flags, message)
    
    state.update(
      stage: new_stage,
      emotional_state: emotional_state,
      trust_level: new_trust,
      last_interaction: Time.current,
      flags: flags
    )
  end

  # Decay old memories periodically
  def decay_old_memories(days_threshold: 30, decay_rate: 0.1)
    MemoryFact.where(chat: @chat)
      .where('last_recalled_at < ?', days_threshold.days.ago)
      .find_each do |memory|
        days_since_recall = (Time.current - memory.last_recalled_at).to_f / 1.day
        new_importance = memory.importance_score * (1.0 - decay_rate) ** (days_since_recall / 30)
        memory.update(importance_score: new_importance)
      end
  end

  private

  def generate_embedding(text)
    client = OpenAI::Client.new
    response = client.embeddings(
      parameters: {
        model: "text-embedding-3-small",
        input: text
      }
    )
    response.dig("data", 0, "embedding")
  rescue => e
    Rails.logger.error "Failed to generate embedding: #{e.message}"
    raise
  end

  def detect_topic(text)
    # Simple keyword-based topic detection
    case text.downcase
    when /family|parent|sister|brother|mom|dad/
      'family'
    when /work|job|career|study|school/
      'career'
    when /hobby|interest|like|enjoy|fun/
      'interests'
    when /feel|emotion|happy|sad|angry/
      'emotions'
    else
      'general'
    end
  end

  def detect_emotion(text)
    # Simple keyword-based emotion detection
    case text.downcase
    when /love|happy|joy|excited|smile/
      'positive'
    when /sad|angry|upset|hate|mad/
      'negative'
    when /worry|anxious|nervous/
      'anxious'
    when /miss|lonely|alone/
      'longing'
    else
      'neutral'
    end
  end

  def detect_context_type(text)
    # Determine the type of information being shared
    case text.downcase
    when /like|love|hate|prefer|favorite/
      'preference'
    when /did|went|saw|visited/
      'event'
    when /feel|think|believe/
      'opinion'
    when /will|going to|plan|future/
      'plan'
    else
      'general'
    end
  end

  def determine_relationship_stage(current_stage, message)
    # Logic to progress relationship stage based on interaction
    case current_stage
    when nil, ''
      'new'
    when 'new'
      message.content.match?(/like|love|heart|feel/) ? 'flirty' : 'new'
    when 'flirty'
      message.content.match?(/love|relationship|together/) ? 'romantic' : 'flirty'
    else
      current_stage
    end
  end

  def analyze_emotional_state(message)
    # Simple emotion analysis
    case message.content.downcase
    when /love|happy|excited/
      'happy'
    when /miss|lonely/
      'missing'
    when /angry|upset|mad/
      'upset'
    when /busy|later|bye/
      'distant'
    else
      'neutral'
    end
  end

  def calculate_trust_change(message)
    # Calculate trust level changes based on interaction
    case message.content.downcase
    when /love|trust|always/
      0.1
    when /hate|never|angry/
      -0.1
    else
      0.01
    end
  end

  def update_relationship_flags(current_flags, message)
    flags = current_flags || {}
    
    # Update flags based on behavior patterns
    flags['long_absence'] = true if message.created_at > 7.days.ago
    flags['consistent'] = true if message.created_at <= 1.day.ago
    flags['emotional_connection'] = true if message.content.match?(/love|feel|heart/)
    
    flags
  end

  def generate_summary(messages)
    # TODO: Use OpenAI to generate a concise summary
    messages.map(&:content).join("\n")
  end

  def analyze_emotion_tone(messages)
    # Analyze overall emotional tone of conversation
    emotions = messages.map { |m| detect_emotion(m.content) }
    emotions.max_by { |e| emotions.count(e) }
  end

  def extract_key_points(messages)
    # TODO: Use OpenAI to extract key points
    {
      topics_discussed: messages.map { |m| detect_topic(m.content) }.uniq,
      emotions_expressed: messages.map { |m| detect_emotion(m.content) }.uniq
    }
  end
end 