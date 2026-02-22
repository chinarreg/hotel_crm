require "rails_helper"

RSpec.describe CsvImportJob, type: :job do
  it "invokes csv import service" do
    service = instance_double(Imports::CsvImportService, call: true)
    allow(Imports::CsvImportService).to receive(:new).and_return(service)

    described_class.new.perform("/tmp/imports/guests.csv", 10)

    expect(Imports::CsvImportService).to have_received(:new).with(file_path: "/tmp/imports/guests.csv", property_id: 10)
    expect(service).to have_received(:call)
  end

  it "re-raises errors for sidekiq retry" do
    service = instance_double(Imports::CsvImportService)
    allow(Imports::CsvImportService).to receive(:new).and_return(service)
    allow(service).to receive(:call).and_raise(StandardError.new("boom"))

    expect { described_class.new.perform("/tmp/imports/guests.csv") }.to raise_error(StandardError, "boom")
  end
end
