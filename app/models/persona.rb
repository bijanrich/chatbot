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

  # Get the complete prompt including personality aspects
  def full_prompt
    [default_prompt, personality_prompt].join("\n\n")
  end
end 