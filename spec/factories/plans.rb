FactoryBot.define do
  factory :plan do
    name { "MyString" }
    stripe_price_id { "MyString" }
    amount { "9.99" }
    interval { "MyString" }
    description { "MyText" }
    features { "MyText" }
  end
end
