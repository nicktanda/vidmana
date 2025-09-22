FactoryBot.define do
  factory :story do
    title { "MyString" }
    description { "MyText" }
    user { nil }
    prompt { "MyText" }
    api_response { "" }
    status { "MyString" }
  end
end
