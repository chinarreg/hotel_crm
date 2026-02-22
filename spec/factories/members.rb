FactoryBot.define do
  factory :member do
    association :property
    full_name { Faker::Name.name }
    sequence(:membership_number) { |n| "RBM-#{n.to_s.rjust(4, '0')}" }
    sequence(:phone) { |n| "900000#{n.to_s.rjust(4, '0')}" }
    sequence(:email) { |n| "member#{n}@example.com" }
    membership_start_date { Date.current }
    membership_expiry_date { Date.current + 1.year }
    status { :active }
  end
end
