class EnhanceMemoryFacts < ActiveRecord::Migration[7.1]
  def change
    create_table :memory_facts do |t|
      t.references :chat, null: false, foreign_key: true
      t.text :summary, null: false
      t.string :topic
      t.string :emotion
      t.string :context_type  # 'preference', 'event', 'relationship', etc.
      t.float :importance_score, default: 1.0
      t.integer :recall_count, default: 0
      t.datetime :last_recalled_at
      t.vector :embedding, dimension: 384  # Using pgvector's vector type
      t.jsonb :metadata  # For additional context, original message IDs, etc.
      t.timestamps
    end

    add_index :memory_facts, :topic
    add_index :memory_facts, :emotion
    add_index :memory_facts, :context_type
    add_index :memory_facts, :importance_score
    add_index :memory_facts, :last_recalled_at
  end
end 