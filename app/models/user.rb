class User < ApplicationRecord
  # Use string IDs
  self.primary_key = :id

  has_many :user_memories, dependent: :destroy
  has_many :short_term_memories, dependent: :destroy
  
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true

  # Override initialize to handle string IDs
  before_create :set_id
  
  private

  def set_id
    self.id ||= SecureRandom.uuid
  end
end 