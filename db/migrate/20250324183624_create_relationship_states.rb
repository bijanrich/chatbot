class CreateRelationshipStates < ActiveRecord::Migration[7.1]
  def change
    create_table :relationship_states do |t|
      t.references :chat, null: false, foreign_key: true
      t.string :stage
      t.string :emotional_state
      t.float :trust_level
      t.datetime :last_interaction
      t.jsonb :flags
      t.jsonb :metadata

      t.timestamps
    end
  end
end
