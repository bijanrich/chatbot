class CreatePsychologicalAnalyses < ActiveRecord::Migration[7.1]
  def change
    create_table :psychological_analyses do |t|
      t.references :user, null: false, foreign_key: true
      t.text :analysis
      t.datetime :analyzed_at

      t.timestamps
    end
  end
end
