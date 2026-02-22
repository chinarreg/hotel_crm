require "rails_helper"

RSpec.describe OperaCsvImportJob, type: :job do
  it "delegates to CsvImportJob" do
    allow(CsvImportJob).to receive(:perform_async)

    described_class.new.perform("/tmp/sample.csv", "sample.csv", 7)

    expect(CsvImportJob).to have_received(:perform_async).with("/tmp/sample.csv", 7)
  end
end
