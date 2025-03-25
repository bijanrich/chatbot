class CreateCreatorProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :creator_profiles do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name
      t.string :onlyfans_username
      t.string :status

      t.timestamps
    end
  end
end
