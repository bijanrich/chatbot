class AddPromptToChatSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :chat_settings, :prompt, :text
  end
end
