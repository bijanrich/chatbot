class UserMemory < ApplicationRecord
  include PgVector::Model

  belongs_to :user

  validates :facts, presence: true
  
  # Constants
  OPENAI_EMBEDDING_MODEL = 'text-embedding-ada-002'
  SIMILARITY_THRESHOLD = 0.8

  # Configure vector column
  has_vector :embedding, dimension: 1024

  # Update or create new facts about the user
  def self.update_facts(user_id, new_fact)
    memory = find_or_initialize_by(user_id: user_id)
    
    # If this is a new memory, initialize facts
    memory.facts ||= ""
    
    # Add the new fact with a timestamp
    memory.facts += "\n#{Time.current.iso8601}: #{new_fact}" unless memory.facts.include?(new_fact)
    
    # Generate embedding for the updated facts
    memory.generate_embedding
    
    memory.save!
  end

  # Retrieve relevant facts based on a query
  def self.retrieve_relevant_facts(user_id, query, limit: 5)
    memory = find_by(user_id: user_id)
    return [] unless memory&.embedding.present?

    # Generate embedding for the query
    query_embedding = OpenAI::Client.new.embeddings(
      parameters: {
        model: OPENAI_EMBEDDING_MODEL,
        input: query
      }
    ).dig("data", 0, "embedding")

    # Find similar facts using vector similarity
    similar_facts = where("cosine_similarity(embedding, ARRAY[?]) > ?", query_embedding, SIMILARITY_THRESHOLD)
      .order("cosine_similarity(embedding, ARRAY[?]) DESC", query_embedding)
      .limit(limit)

    similar_facts.map(&:facts)
  end

  private

  def generate_embedding
    return unless facts_changed?

    response = OpenAI::Client.new.embeddings(
      parameters: {
        model: OPENAI_EMBEDDING_MODEL,
        input: facts
      }
    )

    # Truncate the embedding to 1024 dimensions if needed
    self.embedding = response.dig("data", 0, "embedding").first(1024)
  end
end
