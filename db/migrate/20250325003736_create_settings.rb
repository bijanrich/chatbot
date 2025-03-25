class CreateSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :settings do |t|
      t.string :key, null: false
      t.text :value
      t.string :data_type, default: 'string'
      t.timestamps
    end
    
    add_index :settings, :key, unique: true
    
    # Add the global_prompt setting
    reversible do |dir|
      dir.up do
        execute <<-SQL
          INSERT INTO settings (key, value, data_type, created_at, updated_at)
          VALUES ('global_prompt', 'You are an AI assistant running on the Ollama platform. You aim to be helpful, harmless, and honest in all interactions.', 'text', NOW(), NOW())
        SQL
      end
      
      dir.down do
        execute <<-SQL
          DELETE FROM settings WHERE key = 'global_prompt'
        SQL
      end
    end
  end
end
