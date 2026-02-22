FactoryBot.define do
  factory :guest_stay do
    association :property
    full_name { Faker::Name.name }
    sequence(:phone) { |n| "911111#{n.to_s.rjust(4, '0')}" }
    sequence(:email) { |n| "guest#{n}@example.com" }
    checkin_date { Date.current }
    checkout_date { Date.current + 2.days }
    source_file { "import.csv" }
    imported_at { Time.current }
    sequence(:row_fingerprint) { |n| "fp-#{n}" }
  end
end
