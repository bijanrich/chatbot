class AddMagicLinkFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :magic_link_token, :string
    add_column :users, :magic_link_sent_at, :datetime
    add_index :users, :magic_link_token, unique: true
  end
end
