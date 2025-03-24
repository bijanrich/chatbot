class Message < ApplicationRecord
  belongs_to :chat

  validates :content, presence: true
  validates :role, presence: true
  validates :telegram_chat_id, presence: true, if: :telegram_message?

  scope :unresponded_telegram, -> { where(telegram_chat_id: nil).where(responded: false) }
  scope :by_telegram_chat, ->(chat_id) { where(telegram_chat_id: chat_id) }
  scope :by_created_at, -> { order(created_at: :asc) }

  def telegram_message?
    telegram_chat_id.present?
  end

  def mark_as_responded!
    update!(responded: true)
  end

  def self.create_from_telegram(telegram_chat_id, content)
    chat = Chat.find_or_create_by(telegram_id: telegram_chat_id)
    
    create!(
      chat: chat,
      role: 'user',
      content: content
    )
  end
end
