class CreateChatSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :chat_settings do |t|
      t.references :chat, null: false, foreign_key: true
      t.boolean :show_thinking, null: false, default: false

      t.timestamps
    end
  end
end
