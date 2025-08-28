FactoryBot.define do
  factory :location do
    name { Faker::Address.city }
    description { Faker::Lorem.paragraph(sentence_count: 2) }
    association :story
  end
end