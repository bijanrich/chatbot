class User < ApplicationRecord
  # Include default devise modules. Others available are:
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable 
         # :timeoutable, and :omniauthable

  belongs_to :organization, optional: true
  has_one :creator_profile, dependent: :destroy
  
  # Payment associations
  has_many :payments, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  
  # User type helpers
  def creator?
    creator_profile.present?
  end
  
  def agency_owner?
    organization.present? && organization.users.where(id: id).exists? && !creator?
  end
  
  def user_type
    return 'creator' if creator?
    return 'agency' if agency_owner?
    'user' # default type
  end
  
  def owns_organization?(organization)
    self.organization_id == organization.id && agency_owner?
  end

  def member_of?(organization)
    self.organization_id == organization.id
  end
  
  # Subscription helpers through organization
  def subscribed?
    return false unless organization.present?
    organization.subscriptions.active.exists?
  end
  
  def organization_subscription
    return nil unless organization.present?
    organization.subscriptions.active.first
  end
  
  def subscription_plan_name
    organization_subscription&.plan_name
  end
end
