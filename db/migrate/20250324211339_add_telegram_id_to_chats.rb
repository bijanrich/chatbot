class AddTelegramIdToChats < ActiveRecord::Migration[7.1]
  def change
    add_column :chats, :telegram_id, :bigint
    add_index :chats, :telegram_id, unique: true
  end
end
