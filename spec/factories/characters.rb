FactoryBot.define do
  factory :character do
    name { Faker::Name.name }
    description { Faker::Lorem.paragraph(sentence_count: 2) }
    association :story
  end
end