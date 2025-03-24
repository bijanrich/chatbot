class TelegramMessage < ApplicationRecord
  validates :chat_id, presence: true
  validates :text, presence: true

  scope :unresponded, -> { where(responded: false) }
  scope :responded, -> { where(responded: true) }

  def mark_as_responded!(response_text)
    update!(
      response: response_text,
      responded: true,
      processed_at: Time.current
    )
  end
end
