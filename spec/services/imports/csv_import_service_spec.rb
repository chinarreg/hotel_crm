require "rails_helper"
require "tempfile"

RSpec.describe Imports::CsvImportService, type: :service do
  let(:property) { create(:property) }

  before do
    AppSetting.set(
      "csv_mapping_json",
      {
        "full_name" => "guest_name",
        "phone" => "phone",
        "email" => "email",
        "checkin_date" => "checkin",
        "checkout_date" => "checkout"
      }.to_json
    )
  end

  it "imports csv rows with mapping and normalizes phone" do
    file = Tempfile.new(["guests", ".csv"])
    file.write("guest_name,phone,email,checkin,checkout\nJohn Doe,+91 99887-77665,JOHN@EXAMPLE.COM,2026-02-01,2026-02-03\n")
    file.rewind

    run = described_class.new(file_path: file.path, property_id: property.id).call

    guest = GuestStay.find_by!(row_fingerprint: GuestStay.first.row_fingerprint)
    expect(run).to be_completed
    expect(guest.phone).to eq("9988777665")
    expect(guest.email).to eq("john@example.com")
    expect(guest.imported_at).to be_present
  ensure
    file.close
    file.unlink
  end

  it "is idempotent and does not duplicate on repeated runs" do
    file = Tempfile.new(["guests", ".csv"])
    file.write("guest_name,phone,email,checkin,checkout\nJohn Doe,9999999999,john@example.com,2026-02-01,2026-02-03\n")
    file.rewind

    described_class.new(file_path: file.path, property_id: property.id).call
    described_class.new(file_path: file.path, property_id: property.id).call

    expect(GuestStay.count).to eq(1)
    expect(ImportRun.count).to eq(1)
  ensure
    file.close
    file.unlink
  end

  it "handles bad rows gracefully and tracks failed_rows" do
    file = Tempfile.new(["guests", ".csv"])
    file.write("guest_name,phone,email,checkin,checkout\n,9999999999,john@example.com,2026-02-01,2026-02-03\nJane,1111111111,jane@example.com,invalid,2026-02-03\nGood,2222222222,good@example.com,2026-02-01,2026-02-03\n")
    file.rewind

    run = described_class.new(file_path: file.path, property_id: property.id).call

    expect(run.processed_rows).to eq(1)
    expect(run.failed_rows).to eq(2)
    expect(GuestStay.count).to eq(1)
  ensure
    file.close
    file.unlink
  end
end
