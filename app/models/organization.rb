class Organization < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :creator_profiles, dependent: :destroy
  has_many :subscriptions, dependent: :destroy

  validates :name, presence: true
  validates :billing_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
