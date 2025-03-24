class AddTelegramFieldsToMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :telegram_chat_id, :bigint
    add_column :messages, :responded, :boolean, default: false
    add_column :messages, :processed_at, :datetime

    add_index :messages, :telegram_chat_id
    add_index :messages, :responded
  end
end
