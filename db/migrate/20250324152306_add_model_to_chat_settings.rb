class AddModelToChatSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :chat_settings, :model, :string, default: 'llama3'
  end
end
