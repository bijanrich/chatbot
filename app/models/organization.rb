class Organization < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :creator_profiles, dependent: :destroy
  has_many :subscriptions, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :billing_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  before_validation :generate_slug, if: :name_changed?

  private

  def generate_slug
    self.slug = name.parameterize if name.present?
  end
end
