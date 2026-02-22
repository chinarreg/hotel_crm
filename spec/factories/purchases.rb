FactoryBot.define do
  factory :purchase do
    association :property
    association :member
    amount { 1000.0 }
    purchased_on { Date.current }
    payment_mode { :card }
  end
end
