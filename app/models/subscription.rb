class Subscription < ApplicationRecord
  belongs_to :organization

  validates :plan_name, presence: true
  validates :status, presence: true
  validates :stripe_subscription_id, presence: true, uniqueness: true

  # Status constants
  STATUSES = %w[active past_due canceled incomplete incomplete_expired trialing unpaid].freeze

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :trialing, -> { where(status: 'trialing') }
  scope :canceled, -> { where(status: 'canceled') }

  # Check if subscription is active
  def active?
    status == 'active' || status == 'trialing'
  end

  # Check if subscription is canceled
  def canceled?
    status == 'canceled'
  end

  # Check if subscription is about to expire
  def about_to_expire?
    active? && updated_at.present? && updated_at < 7.days.ago
  end

  # Cancel the subscription
  def cancel!
    update(status: 'canceled')
  end

  # Return the plan associated with this subscription
  def plan
    Plan.find_by(name: plan_name)
  end
end
