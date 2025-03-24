class AddPersonaAndRelationshipStateToChatSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :chat_settings, :persona, :text
    add_column :chat_settings, :relationship_state, :text
  end
end
