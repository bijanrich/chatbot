class AddRelationshipDataToChatSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :chat_settings, :relationship_data, :jsonb
  end
end
