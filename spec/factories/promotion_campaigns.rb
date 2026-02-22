FactoryBot.define do
  factory :promotion_campaign do
    sequence(:name) { |n| "Campaign #{n}" }
    audience_type { :members }
    template_name { "promotion_template" }
    status { :queued }
    variables_json { ["Hello {{name}}"].to_json }
  end
end
