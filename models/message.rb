class Message < ApplicationRecord
  belongs_to :chat
  
  validates :content, presence: true
  validates :role, presence: true, inclusion: { in: ['user', 'assistant'] }
  
  scope :ordered, -> { order(created_at: :asc) }
  
  broadcasts_to :chat
end 