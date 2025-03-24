class UpdateChatTelegramIdConstraint < ActiveRecord::Migration[7.1]
  def up
    # Remove the old index if it exists
    remove_index :chats, :telegram_id if index_exists?(:chats, :telegram_id)
    
    # Add a partial unique index that only applies to active chats
    add_index :chats, :telegram_id, unique: true, where: "active = true", 
              name: 'index_chats_on_telegram_id_where_active'
  end

  def down
    remove_index :chats, name: 'index_chats_on_telegram_id_where_active'
    add_index :chats, :telegram_id, unique: true
  end
end 