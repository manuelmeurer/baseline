# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    first_name { "Peter" }
    last_name { "Müller" }
    sequence(:email) { |n| "user#{n}@example.com" }

    trait :male do
      first_name { "Peter" }
      gender { "male" }
    end

    trait :female do
      first_name { "Petra" }
      gender { "female" }
    end
  end
end
