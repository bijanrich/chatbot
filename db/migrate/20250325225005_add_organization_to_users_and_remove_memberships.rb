class AddOrganizationToUsersAndRemoveMemberships < ActiveRecord::Migration[7.1]
  def change
    # Add organization_id to users for direct association
    add_reference :users, :organization, foreign_key: true, null: true
  end
end
