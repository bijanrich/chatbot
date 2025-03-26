class Payment < ApplicationRecord
  belongs_to :user
  
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true
  validates :stripe_payment_id, uniqueness: true, allow_nil: true
  
  # Status constants
  STATUSES = %w[pending succeeded failed refunded].freeze
  
  # Scopes
  scope :successful, -> { where(status: 'succeeded') }
  scope :pending, -> { where(status: 'pending') }
  scope :failed, -> { where(status: 'failed') }
  
  # Check if payment is successful
  def successful?
    status == 'succeeded'
  end
  
  # Check if payment is pending
  def pending?
    status == 'pending'
  end
  
  # Check if payment is failed
  def failed?
    status == 'failed'
  end
  
  # Mark payment as successful
  def mark_as_succeeded!
    update(status: 'succeeded')
  end
  
  # Mark payment as failed
  def mark_as_failed!
    update(status: 'failed')
  end
end
