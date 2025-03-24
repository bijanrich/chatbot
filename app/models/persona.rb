class Persona < ApplicationRecord
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :default_prompt, presence: true
  validates :personality_traits, presence: true
  validates :emotional_profile, presence: true
  validates :speech_style, presence: true
  validates :memory_behavior, presence: true
  validates :tone, inclusion: { in: %w[neutral sms poetic formal casual] }
  validates :emoji_usage, inclusion: { in: %w[none light moderate heavy] }

  # Associations
  has_many :chat_settings

  # Relationship stages
  RELATIONSHIP_STAGES = %w[stranger acquaintance friend close intimate].freeze
  
  # Attachment styles
  ATTACHMENT_STYLES = %w[secure anxious avoidant fearful].freeze
  
  # Example personality traits
  PERSONALITY_TRAITS = [
    'mysterious', 'romantic', 'jealous', 'caring', 'playful',
    'intellectual', 'adventurous', 'artistic', 'spiritual', 'ambitious'
  ].freeze

  # Scopes
  scope :active, -> { where(active: true) }

  def self.default
    find_by(name: 'default') || first
  end

  # Get or initialize relationship data for a chat
  def relationship_data_for(chat)
    # Using JSON column to store relationship data
    data = chat_settings.find_by(chat_id: chat.id)&.relationship_data || {}
    
    # Initialize with defaults if empty
    if data.blank?
      data = {
        'stage' => 'stranger',
        'intimacy_score' => 0,
        'attachment_style' => default_attachment_style,
        'interaction_count' => 0,
        'last_interaction' => nil,
        'key_memories' => [],
        'engagement_metrics' => {
          'avg_response_time' => nil,
          'avg_message_length' => nil,
          'sentiment_score' => nil
        }
      }
      
      # Save the initialized data if we have a chat_setting
      if chat_setting = chat_settings.find_by(chat_id: chat.id)
        chat_setting.update(relationship_data: data)
      end
    end
    
    data
  end
  
  # Update relationship data after an interaction
  def record_interaction(chat, message)
    settings = ChatSetting.for_chat(chat.id)
    return unless settings.persona_id == id
    
    data = relationship_data_for(chat)
    data['interaction_count'] = (data['interaction_count'] || 0) + 1
    data['last_interaction'] = Time.now.iso8601
    
    # Simple evolution of relationship stage based on interaction count
    data['stage'] = evolve_relationship_stage(data)
    
    # Update intimacy score (simple implementation)
    data['intimacy_score'] = calculate_intimacy_score(data, message)
    
    # Save updated data
    settings.update(relationship_data: data)
    
    data
  end
  
  # Combine all personality aspects into a comprehensive prompt addition
  def personality_prompt
    parts = []
    parts << "Your personality is: #{personality_traits.join(', ')}."
    
    case tone
    when 'sms'
      parts << "You communicate in a casual, SMS-like style with short messages."
    when 'poetic'
      parts << "You express yourself poetically and use metaphors when appropriate."
    when 'formal'
      parts << "You maintain a formal and professional tone."
    when 'casual'
      parts << "You keep things casual and friendly."
    end

    case emoji_usage
    when 'none'
      parts << "You don't use emojis."
    when 'light'
      parts << "You use emojis sparingly."
    when 'moderate'
      parts << "You use emojis regularly to express emotions."
    when 'heavy'
      parts << "You love using emojis frequently! 🌟"
    end

    if emotional_profile.present?
      parts << "Your emotional characteristics: "
      emotional_profile.each do |trait, value|
        parts << "- #{trait.humanize}: #{value}"
      end
    end

    if speech_style.present?
      parts << "Your speech style: "
      speech_style.each do |trait, value|
        parts << "- #{trait.humanize}: #{value}"
      end
    end

    parts.join("\n")
  end

  # Get relationship prompt additions based on stage and history
  def relationship_prompt(chat)
    data = relationship_data_for(chat)
    stage = data['stage']
    
    prompt = "\nYour relationship with the user is at the '#{stage}' stage. "
    
    case stage
    when 'stranger'
      prompt += "You're still getting to know each other. Be welcoming but maintain some distance."
    when 'acquaintance'
      prompt += "You've had a few conversations. Show that you remember past interactions, but keep exploring common interests."
    when 'friend'
      prompt += "You have established rapport. Use a warmer tone, reference inside jokes, and show genuine interest."
    when 'close'
      prompt += "You have a strong connection. Be supportive, understanding, and show vulnerability appropriate to your persona."
    when 'intimate'
      prompt += "You have a deep bond. Show deep understanding, anticipate needs, and maintain strong emotional connection."
    end
    
    # Add attachment style influences
    attachment_style = data['attachment_style']
    prompt += "\n\nYour attachment style is '#{attachment_style}'. "
    
    case attachment_style
    when 'secure'
      prompt += "You're comfortable with closeness and separation. Respond with consistency and emotional availability."
    when 'anxious'
      prompt += "You seek more closeness and worry about abandonment. Show more enthusiasm when the user returns after absence."
    when 'avoidant'
      prompt += "You value independence. Maintain some emotional distance while still being supportive."
    when 'fearful'
      prompt += "You desire closeness but are afraid of being hurt. Show vulnerability but may pull back if feeling too exposed."
    end
    
    prompt
  end

  # Get the complete prompt including personality aspects and relationship context
  def full_prompt(chat = nil)
    prompt = default_prompt
    prompt += "\n\n" + personality_prompt
    
    # Add relationship context if chat is provided
    if chat.present?
      prompt += "\n\n" + relationship_prompt(chat)
    end
    
    prompt
  end
  
  private
  
  def default_attachment_style
    # Default attachment style based on personality traits
    if personality_traits.include?('jealous') || personality_traits.include?('romantic')
      'anxious'
    elsif personality_traits.include?('mysterious') || personality_traits.include?('independent')
      'avoidant'  
    elsif personality_traits.include?('caring') || personality_traits.include?('nurturing')
      'secure'
    else
      'secure' # Default to secure
    end
  end
  
  def evolve_relationship_stage(data)
    interaction_count = data['interaction_count'] || 0
    current_stage = data['stage'] || 'stranger'
    
    # Simple evolution based on interaction count
    case interaction_count
    when 0..5
      'stranger'
    when 6..15
      'acquaintance'
    when 16..30
      'friend'
    when 31..50
      'close'
    else
      'intimate'
    end
  end
  
  def calculate_intimacy_score(data, message)
    # Start with current score
    score = data['intimacy_score'] || 0
    
    # Simple implementation: increase score based on message length and content
    # This would be much more sophisticated in practice with sentiment analysis, etc.
    
    # Increase based on message length (longer messages = more engagement)
    content_length = message.content.to_s.length
    score += [content_length / 100.0, 0.5].min # Cap at 0.5 per message
    
    # Cap total score at 100
    [score, 100].min
  end
end 