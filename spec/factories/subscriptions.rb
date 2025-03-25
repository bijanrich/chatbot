FactoryBot.define do
  factory :subscription do
    organization { nil }
    status { "MyString" }
    plan_name { "MyString" }
    stripe_subscription_id { "MyString" }
  end
end
