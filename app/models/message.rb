class Message < ApplicationRecord
  belongs_to :chat

  validates :content, presence: true
  validates :role, presence: true

  scope :unresponded, -> { where(responded: false) }
  scope :by_created_at, -> { order(created_at: :asc) }

  def self.create_from_telegram(telegram_chat_id, content)
    # Find the active chat for this telegram_id
    chat = Chat.find_by(telegram_id: telegram_chat_id, active: true)
    
    # If no active chat is found, create a new one (should never happen)
    unless chat
      Rails.logger.warn("No active chat found for telegram_id: #{telegram_chat_id}. Creating a new one.")
      chat = Chat.create!(telegram_id: telegram_chat_id, title: "Telegram Chat #{telegram_chat_id}")
    end
    
    # Create the message with the chat
    create!(
      chat: chat,
      role: 'user',
      content: content,
      telegram_chat_id: telegram_chat_id # Keep this for backward compatibility
    )
  end
  
  def mark_as_responded!
    update!(responded: true)
  end
end
