class Chat < ApplicationRecord
  has_many :messages, dependent: :destroy
  has_one :chat_setting, dependent: :destroy

  validates :title, presence: true
end
