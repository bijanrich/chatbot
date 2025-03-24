class AddOllamaIpToChatSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :chat_settings, :ollama_ip, :string
  end
end
