class EnhanceMemoryFacts < ActiveRecord::Migration[7.1]
  def up
    # Ensure the vector extension is enabled
    execute "CREATE EXTENSION IF NOT EXISTS vector"
    
    # Add new columns to the existing memory_facts table
    add_column :memory_facts, :context_type, :string
    add_column :memory_facts, :recall_count, :integer, default: 0
    add_column :memory_facts, :last_recalled_at, :datetime
    add_column :memory_facts, :metadata, :jsonb
    
    # Add vector column using raw SQL
    execute "ALTER TABLE memory_facts ADD COLUMN embedding vector(384)"
    
    # Add indexes for new columns
    add_index :memory_facts, :context_type
    add_index :memory_facts, :last_recalled_at
  end
  
  def down
    # Remove the added columns
    remove_column :memory_facts, :embedding
    remove_column :memory_facts, :context_type
    remove_column :memory_facts, :recall_count
    remove_column :memory_facts, :last_recalled_at
    remove_column :memory_facts, :metadata
  end
end 