class User < ApplicationRecord
  # Include default devise modules. Others available are:
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable 
         # :timeoutable, and :omniauthable

  belongs_to :organization
  
  # Payment associations
  has_many :payments, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }, allow_blank: true
  
  # Organization helpers
  def is_admin_of_organization?
    organization.users.where(id: id).exists?
  end
  
  def admin?
    is_admin_of_organization?
  end
  
  def owns_organization?(org)
    self.organization_id == org.id && admin?
  end

  def member_of?(org)
    self.organization_id == org.id
  end
  
  # Subscription helpers through organization
  def subscribed?
    organization.subscriptions.active.exists?
  end
  
  def organization_subscription
    organization.subscriptions.active.first
  end
  
  def subscription_plan_name
    organization_subscription&.plan_name
  end
end
