class CreateConversationSummaries < ActiveRecord::Migration[7.1]
  def change
    create_table :conversation_summaries do |t|
      t.references :chat, null: false, foreign_key: true
      t.text :summary, null: false
      t.string :emotion_tone
      t.jsonb :key_points, default: {}
      t.vector :embedding, dimension: 384
      t.datetime :start_time
      t.datetime :end_time
      t.integer :message_count
      t.float :importance_score, default: 1.0
      t.timestamps
    end

    add_index :conversation_summaries, :emotion_tone
    add_index :conversation_summaries, :start_time
    add_index :conversation_summaries, :end_time
    add_index :conversation_summaries, :importance_score
  end
end 