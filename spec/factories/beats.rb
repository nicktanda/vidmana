FactoryBot.define do
  factory :beat do
    title { Faker::Book.title }
    description { Faker::Lorem.paragraph(sentence_count: 5) }
    association :story
  end
end