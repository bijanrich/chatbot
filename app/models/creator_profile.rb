class CreatorProfile < ApplicationRecord
  belongs_to :organization

  STATUSES = %w[active inactive pending suspended].freeze

  validates :name, presence: true
  validates :onlyfans_username, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
  scope :pending, -> { where(status: 'pending') }
  scope :suspended, -> { where(status: 'suspended') }
end
