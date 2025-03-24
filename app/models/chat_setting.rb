class ChatSetting < ApplicationRecord
  belongs_to :chat

  validates :show_thinking, inclusion: { in: [true, false] }

  # Get or create settings for a chat
  def self.for_chat(chat_id)
    find_or_create_by!(chat_id: chat_id)
  end

  # Toggle thinking mode
  def toggle_thinking!
    update!(show_thinking: !show_thinking)
  end
end
