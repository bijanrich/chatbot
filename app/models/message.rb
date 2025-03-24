class Message < ApplicationRecord
  belongs_to :chat

  validates :content, presence: true
  validates :role, presence: true

  scope :unresponded, -> { where(responded: false) }
  scope :by_created_at, -> { order(created_at: :asc) }

  def self.create_from_telegram(telegram_chat_id, content)
    chat = Chat.find_or_create_by(telegram_id: telegram_chat_id)
    
    create!(
      chat: chat,
      role: 'user',
      content: content
    )
  end
  
  def mark_as_responded!
    update!(responded: true)
  end
end
