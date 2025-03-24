class CreateUserMemories < ActiveRecord::Migration[7.1]
  def change
    create_table :user_memories do |t|
      t.references :user, null: false, foreign_key: true
      t.text :facts, null: false
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        execute <<-SQL
          ALTER TABLE user_memories ADD COLUMN embedding vector(1536);
          CREATE INDEX user_memories_embedding_idx ON user_memories USING ivfflat (embedding vector_l2_ops) WITH (lists = 100);
        SQL
      end

      dir.down do
        execute <<-SQL
          DROP INDEX IF EXISTS user_memories_embedding_idx;
          ALTER TABLE user_memories DROP COLUMN IF EXISTS embedding;
        SQL
      end
    end
  end
end
