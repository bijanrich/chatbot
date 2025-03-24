class Message < ApplicationRecord
  belongs_to :chat

  validates :content, presence: true
  validates :role, presence: true
  validates :telegram_chat_id, presence: true, if: :telegram_message?

  scope :unresponded_telegram, -> { where(telegram_chat_id: nil).where(responded: false) }
  scope :by_telegram_chat, ->(chat_id) { where(telegram_chat_id: chat_id) }

  def telegram_message?
    telegram_chat_id.present?
  end

  def mark_as_responded!
    update!(
      responded: true,
      processed_at: Time.current
    )
  end

  def self.create_from_telegram(telegram_chat_id, text)
    # Find or create a chat for this Telegram conversation
    chat = Chat.find_or_create_by!(title: "Telegram Chat #{telegram_chat_id}")

    create!(
      content: text,
      role: 'user',
      telegram_chat_id: telegram_chat_id,
      chat: chat,
      responded: false
    )
  end
end
