require "rails_helper"
require "tempfile"

RSpec.describe Imports::GuestImportService, type: :service do
  let(:property) { create(:property) }

  it "imports rows idempotently using checksum and fingerprint" do
    file = Tempfile.new(["guests", ".csv"])
    file.write("full_name,phone,email,checkin_date,checkout_date\nJohn Doe,9999999999,john@example.com,2026-02-01,2026-02-03\n")
    file.rewind

    described_class.new(file_path: file.path, source_file: "guests.csv", property_id: property.id).call
    described_class.new(file_path: file.path, source_file: "guests.csv", property_id: property.id).call

    expect(GuestStay.count).to eq(1)
    expect(ImportRun.count).to eq(1)
  ensure
    file.close
    file.unlink
  end
end
