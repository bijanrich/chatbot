class CreateTelegramMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :telegram_messages do |t|
      t.bigint :chat_id, null: false
      t.text :text, null: false
      t.text :response
      t.boolean :responded, default: false, null: false
      t.datetime :processed_at

      t.timestamps
    end

    add_index :telegram_messages, :chat_id
    add_index :telegram_messages, :responded
  end
end
