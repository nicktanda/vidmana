FactoryBot.define do
  factory :universe_share do
    universe { nil }
    user { nil }
    permission_level { "MyString" }
  end
end
