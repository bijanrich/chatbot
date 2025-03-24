class CreateConversationSummaries < ActiveRecord::Migration[7.1]
  def up
    # Ensure the vector extension is enabled
    execute "CREATE EXTENSION IF NOT EXISTS vector"
    
    # Create table with standard columns
    create_table :conversation_summaries do |t|
      t.references :chat, null: false, foreign_key: true
      t.text :summary, null: false
      t.string :emotion_tone
      t.jsonb :key_points, default: {}
      t.datetime :start_time
      t.datetime :end_time
      t.integer :message_count
      t.float :importance_score
      
      t.timestamps
    end
    
    # Add vector column using raw SQL
    execute "ALTER TABLE conversation_summaries ADD COLUMN embedding vector(384)"
    
    # Add indexes
    add_index :conversation_summaries, :emotion_tone
    add_index :conversation_summaries, :start_time
    add_index :conversation_summaries, :end_time
    add_index :conversation_summaries, :importance_score
  end
  
  def down
    drop_table :conversation_summaries
  end
end 