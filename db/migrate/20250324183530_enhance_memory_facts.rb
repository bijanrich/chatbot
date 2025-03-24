class EnhanceMemoryFacts < ActiveRecord::Migration[7.1]
  def up
    # Ensure the vector extension is enabled
    execute "CREATE EXTENSION IF NOT EXISTS vector"
    
    # Add columns to the existing memory_facts table
    add_column :memory_facts, :summary, :text, null: false, default: ''
    add_column :memory_facts, :topic, :string
    add_column :memory_facts, :emotion, :string
    add_column :memory_facts, :context_type, :string
    add_column :memory_facts, :importance_score, :float, default: 1.0
    add_column :memory_facts, :recall_count, :integer, default: 0
    add_column :memory_facts, :last_recalled_at, :datetime
    add_column :memory_facts, :metadata, :jsonb
    
    # Add foreign key if it doesn't exist
    add_reference :memory_facts, :chat, null: false, foreign_key: true, index: true unless column_exists?(:memory_facts, :chat_id)
    
    # Add vector column using raw SQL
    execute "ALTER TABLE memory_facts ADD COLUMN embedding vector(384)"
    
    # Add indexes
    add_index :memory_facts, :topic
    add_index :memory_facts, :emotion
    add_index :memory_facts, :context_type
    add_index :memory_facts, :importance_score
    add_index :memory_facts, :last_recalled_at
  end
  
  def down
    # Remove the added columns
    remove_column :memory_facts, :embedding
    remove_column :memory_facts, :summary
    remove_column :memory_facts, :topic
    remove_column :memory_facts, :emotion
    remove_column :memory_facts, :context_type
    remove_column :memory_facts, :importance_score
    remove_column :memory_facts, :recall_count
    remove_column :memory_facts, :last_recalled_at
    remove_column :memory_facts, :metadata
    remove_reference :memory_facts, :chat
  end
end 