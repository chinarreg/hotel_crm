require "rails_helper"
require "csv"

RSpec.describe Imports::OperaCsvParser, type: :service do
  it "uses mapping from settings including guest_name/checkin/checkout aliases" do
    AppSetting.set("csv_mapping_json", { "full_name" => "guest_name", "checkin_date" => "checkin", "checkout_date" => "checkout", "phone" => "phone", "email" => "email" }.to_json)
    row = CSV::Row.new(%w[guest_name phone email checkin checkout], ["John", "999", "JOHN@example.com", "2026-02-01", "2026-02-03"])

    parsed = described_class.new(row).call

    expect(parsed[:full_name]).to eq("John")
    expect(parsed[:checkin_date]).to eq(Date.parse("2026-02-01"))
    expect(parsed[:checkout_date]).to eq(Date.parse("2026-02-03"))
  end

  it "falls back when mapping json is invalid" do
    AppSetting.set("csv_mapping_json", "{invalid")
    row = CSV::Row.new(%w[full_name phone email checkin_date checkout_date], ["Jane", "123", "jane@example.com", "2026-02-02", "2026-02-04"])

    parsed = described_class.new(row).call

    expect(parsed[:full_name]).to eq("Jane")
  end
end
