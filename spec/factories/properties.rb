FactoryBot.define do
  factory :property do
    sequence(:name) { |n| "Property #{n}" }
    sequence(:code) { |n| "PROP#{n}" }
    active { true }
  end
end
