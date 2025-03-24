class ShortTermMemory < ApplicationRecord
  belongs_to :user

  validates :message, :role, :timestamp, presence: true
  validates :role, inclusion: { in: ['user', 'assistant'] }

  # Constants
  MAX_MEMORY_SIZE = 10  # Keep last 10 messages

  # Store a new message in short-term memory
  def self.store_message(user_id, message, role)
    # Create new memory entry
    create!(
      user_id: user_id,
      message: message,
      role: role,
      timestamp: Time.current
    )

    # Prune old messages if we exceed MAX_MEMORY_SIZE
    prune_old_messages(user_id)
  end

  # Retrieve recent message history
  def self.recent_history(user_id)
    where(user_id: user_id)
      .order(timestamp: :desc)
      .limit(MAX_MEMORY_SIZE)
      .order(timestamp: :asc)  # Return in chronological order
  end

  # Format recent history for LLM context
  def self.format_for_context(user_id)
    recent_history(user_id).map do |memory|
      {
        role: memory.role,
        content: memory.message,
        timestamp: memory.timestamp.iso8601
      }
    end
  end

  private

  def self.prune_old_messages(user_id)
    old_messages = where(user_id: user_id)
      .order(timestamp: :desc)
      .offset(MAX_MEMORY_SIZE)
    
    old_messages.destroy_all if old_messages.exists?
  end
end
