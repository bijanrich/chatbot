class AddUserIdToCreatorProfiles < ActiveRecord::Migration[7.1]
  def change
    add_reference :creator_profiles, :user, null: false, foreign_key: true
  end
end
