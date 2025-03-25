class AddOnlyFansFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :onlyfans_id, :string
    add_column :users, :profile_url, :string
    add_column :users, :bio, :text
    add_column :users, :last_active, :datetime
    add_column :users, :message_rate, :integer
    add_column :users, :max_daily_messages, :integer
    add_column :users, :response_delay_min, :integer
    add_column :users, :response_delay_max, :integer
    add_column :users, :active_conversations, :integer
    add_column :users, :total_messages_sent, :integer
  end
end
