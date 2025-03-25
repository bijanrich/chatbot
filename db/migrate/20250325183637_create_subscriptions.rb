class CreateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :subscriptions do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :status
      t.string :plan_name
      t.string :stripe_subscription_id

      t.timestamps
    end
  end
end
