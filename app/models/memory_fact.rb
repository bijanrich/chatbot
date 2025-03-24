class MemoryFact < ApplicationRecord
  belongs_to :chat

  validates :summary, presence: true
  validates :topic, presence: true
  validates :emotion, presence: true
  validates :importance_score, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }

  # Add embedding column if using Postgres with pgvector
  has_pg_vector :embedding, dimensions: 384, if: -> { connection.extension_enabled?('vector') }

  # Find recent memories
  def self.find_recent(chat_id, limit: 5)
    where(chat_id: chat_id)
      .order(created_at: :desc)
      .limit(limit)
  end
  
  # Find memories by relevance to a specific keyword
  def self.find_by_topic(chat_id, topic, limit: 5)
    where(chat_id: chat_id, topic: topic)
      .order(importance_score: :desc)
      .limit(limit)
  end
  
  # Find memories by semantic similarity if embedding is available
  def self.find_by_embedding(chat_id, embedding, limit: 5)
    if defined?(Pgvector::Vector) && embedding.present?
      begin
        vector = Pgvector::Vector.new(embedding)
        where(chat_id: chat_id)
          .order(Arel.sql("embedding <-> '#{vector.to_s}'::vector"))
          .limit(limit)
      rescue => e
        Rails.logger.error("Error in vector search: #{e.message}")
        find_recent(chat_id, limit: limit)
      end
    else
      # Fall back to recent memories if embeddings aren't available
      find_recent(chat_id, limit: limit)
    end
  end
end 