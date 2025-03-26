FactoryBot.define do
  factory :payment do
    amount { "9.99" }
    status { "MyString" }
    stripe_payment_id { "MyString" }
    payment_method { "MyString" }
    user { nil }
  end
end
