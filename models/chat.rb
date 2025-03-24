class Chat < ApplicationRecord
  has_many :messages, dependent: :destroy
  
  validates :title, presence: true
  
  def last_message
    messages.order(created_at: :desc).first
  end
end 