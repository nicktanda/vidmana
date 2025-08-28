FactoryBot.define do
  factory :story do
    title { Faker::Book.unique.title }
    description { Faker::Lorem.paragraph(sentence_count: 3) }
    association :user
  end
end