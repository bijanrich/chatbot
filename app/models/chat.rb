class Chat < ApplicationRecord
  has_many :messages, dependent: :destroy
  has_one :chat_setting, dependent: :destroy
  has_many :memory_facts, dependent: :destroy

  validates :title, presence: true, unless: -> { telegram_id.present? }
  
  # Generate a title if none exists but telegram_id is present
  before_validation :set_default_title, if: -> { title.blank? && telegram_id.present? }
  
  private
  
  def set_default_title
    self.title = "Telegram Chat #{telegram_id}"
  end
end
