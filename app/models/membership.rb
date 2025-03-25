class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  ROLES = %w[owner admin member].freeze

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :organization_id }

  scope :owners, -> { where(role: 'owner') }
  scope :admins, -> { where(role: 'admin') }
  scope :members, -> { where(role: 'member') }
end
