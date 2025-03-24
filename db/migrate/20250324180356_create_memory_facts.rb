class CreateMemoryFacts < ActiveRecord::Migration[7.1]
  def change
    create_table :memory_facts do |t|
      t.references :chat, null: false, foreign_key: true
      t.text :summary, null: false
      t.string :topic, null: false
      t.string :emotion, null: false
      t.integer :importance_score, null: false, default: 5
      t.timestamps
    end
    
    add_index :memory_facts, [:chat_id, :topic]
  end
end
