class User < ApplicationRecord
  # Include default devise modules. Others available are:
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable 
         # :timeoutable, and :omniauthable

  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships

  validates :email, presence: true, uniqueness: true
  
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
