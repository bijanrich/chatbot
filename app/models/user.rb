class User < ApplicationRecord
  # Include default devise modules. Others available are:
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable 
         # :timeoutable, and :omniauthable

  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships
  has_one :creator_profile, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  
  # User role helpers
  def agency_user?
    memberships.exists?(role: ['admin', 'owner'])
  end
  
  def creator?
    creator_profile.present?
  end
  
  def role
    return 'agency' if agency_user?
    return 'creator' if creator?
    'user' # default role
  end
  
  def admin_of?(organization)
    memberships.exists?(organization: organization, role: 'admin')
  end

  def owner_of?(organization)
    memberships.exists?(organization: organization, role: 'owner')
  end

  def member_of?(organization)
    memberships.exists?(organization: organization)
  end
end
