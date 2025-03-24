FactoryBot.define do
  factory :telegram_message do
    chat_id { "" }
    text { "MyText" }
    response { "MyText" }
    responded { false }
    processed_at { "2025-03-24 05:18:23" }
  end
end
