class CreateOrganizations < ActiveRecord::Migration[7.1]
  def change
    create_table :organizations do |t|
      t.string :name
      t.string :slug
      t.string :billing_email
      t.string :stripe_customer_id

      t.timestamps
    end
  end
end
