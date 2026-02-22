require "rails_helper"

RSpec.describe ImapFetchJob, type: :job do
  it "has retry options for transient failures" do
    expect(described_class.sidekiq_options_hash["retry"]).to eq(10)
    expect(described_class.sidekiq_options_hash["queue"]).to eq(:low)
  end

  it "enqueues csv import jobs for fetched files" do
    result = Imap::ImapFetcherService::FetchResult.new(
      files: [{ path: "/tmp/imports/a.csv", name: "a.csv", uid: 1, checksum: "x" }],
      errors: []
    )

    allow(Imap::ImapFetcherService).to receive(:new).and_return(instance_double(Imap::ImapFetcherService, call: result))
    allow(CsvImportJob).to receive(:perform_async)

    described_class.new.perform(9)

    expect(CsvImportJob).to have_received(:perform_async).with("/tmp/imports/a.csv", 9)
  end

  it "raises when fetch has message-level failures so Sidekiq retries" do
    result = Imap::ImapFetcherService::FetchResult.new(files: [], errors: [{ uid: 2, error: "Timeout::Error" }])
    allow(Imap::ImapFetcherService).to receive(:new).and_return(instance_double(Imap::ImapFetcherService, call: result))

    expect { described_class.new.perform }.to raise_error(RuntimeError, /completed with 1 failed messages/)
  end
end
