FactoryBot.define do
  factory :import_run do
    association :property
    source_file { "guest_data.csv" }
    sequence(:source_checksum) { |n| "checksum-#{n}" }
    status { :queued }
    processed_rows { 0 }
    failed_rows { 0 }
  end
end
