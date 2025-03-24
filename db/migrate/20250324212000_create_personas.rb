class CreatePersonas < ActiveRecord::Migration[7.1]
  def change
    create_table :personas do |t|
      t.string :name, null: false
      t.text :description
      t.text :default_prompt, null: false
      t.jsonb :personality_traits, default: [], null: false
      t.string :tone, default: 'neutral'
      t.string :emoji_usage, default: 'light'
      t.jsonb :emotional_profile, default: {}, null: false
      t.jsonb :speech_style, default: {}, null: false
      t.jsonb :memory_behavior, default: {}, null: false
      t.timestamps
    end

    add_index :personas, :name, unique: true
  end
end 