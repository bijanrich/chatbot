FactoryBot.define do
  factory :membership do
    user { nil }
    organization { nil }
    role { "MyString" }
  end
end
