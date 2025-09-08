FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { "StrongP@ssw0rd123!" }
    password_confirmation { "StrongP@ssw0rd123!" }
  end
end