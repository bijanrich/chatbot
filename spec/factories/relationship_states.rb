FactoryBot.define do
  factory :relationship_state do
    chat { nil }
    stage { "MyString" }
    emotional_state { "MyString" }
    trust_level { 1.5 }
    last_interaction { "2025-03-24 12:36:24" }
    flags { "" }
    metadata { "" }
  end
end
