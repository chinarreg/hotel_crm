FactoryBot.define do
  factory :campaign_recipient do
    association :promotion_campaign
    sequence(:phone) { |n| "900001#{n.to_s.rjust(4, '0')}" }
    full_name { "Guest User" }
    source_type { "member" }
    status { :pending }
    attempt_count { 0 }
  end
end
