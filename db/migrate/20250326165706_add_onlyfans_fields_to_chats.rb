class AddOnlyfansFieldsToChats < ActiveRecord::Migration[7.1]
  def change
    add_reference :chats, :creator_profile, null: true, foreign_key: true
    add_column :chats, :onlyfans_username, :string
    add_index :chats, :onlyfans_username

    # If you have existing chats, you'll need to assign them to a default creator_profile
    # Uncomment and modify this if needed:
    # CreatorProfile.first.tap do |default_profile|
    #   if default_profile
    #     Chat.update_all(creator_profile_id: default_profile.id)
    #   end
    # end

    # Then make creator_profile required
    # Uncomment this after handling existing records:
    # change_column_null :chats, :creator_profile_id, false
  end
end
