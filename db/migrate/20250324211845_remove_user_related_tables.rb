class RemoveUserRelatedTables < ActiveRecord::Migration[7.1]
  def up
    # Remove foreign keys first
    remove_foreign_key :short_term_memories, :users if foreign_key_exists?(:short_term_memories, :users)
    remove_foreign_key :user_memories, :users if foreign_key_exists?(:user_memories, :users)
    
    # Drop tables
    drop_table :users if table_exists?(:users)
    drop_table :user_memories if table_exists?(:user_memories)
    drop_table :short_term_memories if table_exists?(:short_term_memories)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end 