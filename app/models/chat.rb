class Chat < ApplicationRecord
  belongs_to :creator_profile
  has_many :messages, dependent: :destroy
  has_one :chat_setting, dependent: :destroy
  has_one :psychological_analysis, dependent: :destroy
  has_one :relationship_state, dependent: :destroy
  has_many :memory_facts, dependent: :destroy

  validates :title, presence: true, unless: -> { telegram_id.present? }
  validates :telegram_id, uniqueness: { scope: :active, conditions: -> { where(active: true) } }, if: -> { active? && telegram_id.present? }
  validates :onlyfans_username, presence: true
  validates :creator_profile, presence: true
  
  # Generate a title if none exists but telegram_id is present
  before_validation :set_default_title, if: -> { title.blank? && telegram_id.present? }
  
  scope :active, -> { where(active: true) }

  after_create :create_chat_setting
  after_create :create_relationship_state

  def self.find_or_create_by_telegram(telegram_id)
    # First try to find an active chat
    chat = active.find_by(telegram_id: telegram_id)
    
    # If no active chat found, create a new one
    chat || create!(telegram_id: telegram_id, active: true)
  end
  
  private
  
  def set_default_title
    self.title = "Telegram Chat #{telegram_id}"
  end

  def create_chat_setting
    build_chat_setting.save
  end

  def create_relationship_state
    build_relationship_state.save
  end
end
