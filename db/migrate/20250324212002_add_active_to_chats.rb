class AddActiveToChats < ActiveRecord::Migration[7.1]
  def change
    add_column :chats, :active, :boolean, default: true
    add_index :chats, [:telegram_id, :active]
  end
end 