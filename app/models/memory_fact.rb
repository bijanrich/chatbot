class MemoryFact < ApplicationRecord
  belongs_to :chat

  validates :summary, presence: true
  validates :topic, presence: true
  validates :emotion, presence: true
  validates :importance_score, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Find recent memories
  def self.find_recent(chat_id, limit: 5)
    where(chat_id: chat_id)
      .order(created_at: :desc)
      .limit(limit)
  end
  
  # Find memories by relevance to a specific keyword
  def self.find_by_topic(chat_id, topic, limit: 5)
    where(chat_id: chat_id)
      .where("topic ILIKE ?", "%#{topic}%")
      .order(importance_score: :desc)
      .limit(limit)
  end
end 