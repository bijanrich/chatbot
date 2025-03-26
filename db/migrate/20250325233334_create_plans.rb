class CreatePlans < ActiveRecord::Migration[7.1]
  def change
    create_table :plans do |t|
      t.string :name
      t.string :stripe_price_id
      t.decimal :amount
      t.string :interval
      t.text :description
      t.text :features

      t.timestamps
    end
  end
end
