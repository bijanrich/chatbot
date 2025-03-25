class Subscription < ApplicationRecord
  belongs_to :organization

  STATUSES = %w[active trialing past_due canceled unpaid].freeze
  PLAN_NAMES = %w[starter professional enterprise].freeze

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :plan_name, presence: true, inclusion: { in: PLAN_NAMES }
  validates :stripe_subscription_id, presence: true, uniqueness: true
  validates :organization_id, uniqueness: true

  scope :active, -> { where(status: 'active') }
  scope :trialing, -> { where(status: 'trialing') }
  scope :past_due, -> { where(status: 'past_due') }
  scope :canceled, -> { where(status: 'canceled') }
  scope :unpaid, -> { where(status: 'unpaid') }
end
