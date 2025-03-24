class CreateShortTermMemories < ActiveRecord::Migration[7.1]
  def change
    create_table :short_term_memories do |t|
      t.references :user, null: false, foreign_key: true
      t.text :message, null: false
      t.string :role, null: false
      t.datetime :timestamp, null: false

      t.timestamps

      t.index [:user_id, :timestamp], order: { timestamp: :desc }
    end
  end
end
