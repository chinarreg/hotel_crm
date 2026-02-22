FactoryBot.define do
  factory :voucher do
    association :property
    association :member
    sequence(:voucher_code) { |n| "VCH-#{n}" }
    issued_on { Date.current }
    expiry_date { Date.current + 30.days }
    status { :issued }
  end
end
