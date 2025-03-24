class AddPersonaToChatSettings < ActiveRecord::Migration[7.1]
  def change
    add_reference :chat_settings, :persona, foreign_key: true
  end
end 