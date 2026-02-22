require "rails_helper"
require "fileutils"

RSpec.describe Imap::ImapFetcherService, type: :service do
  let(:imap) { instance_double(Net::IMAP) }
  let(:imports_dir) { Rails.root.join("tmp", "imports") }

  before do
    FileUtils.mkdir_p(imports_dir)
    FileUtils.rm_f(Dir[imports_dir.join("*")])

    AppSetting.set("imap_host", "imap.example.com")
    AppSetting.set("imap_port", "993")
    AppSetting.set("imap_username", "ops@example.com")
    AppSetting.set("imap_password", "secret")
    AppSetting.set("imap_folder", "INBOX")

    allow(imap).to receive(:disconnected?).and_return(false)
    allow(imap).to receive(:login)
    allow(imap).to receive(:select)
    allow(imap).to receive(:logout)
    allow(imap).to receive(:disconnect)
  end

  it "fetches unread emails, saves csv attachments, and marks seen" do
    raw = <<~MAIL
      From: ops@example.com
      To: crm@example.com
      Subject: Guests
      MIME-Version: 1.0
      Content-Type: multipart/mixed; boundary="ABC"

      --ABC
      Content-Type: text/plain

      hello
      --ABC
      Content-Type: text/csv; name="guests.csv"
      Content-Disposition: attachment; filename="guests.csv"
      Content-Transfer-Encoding: base64

      ZnVsbF9uYW1lLHBob25lCkpvaG4sOTk5OTk5OTk5OQ==
      --ABC--
    MAIL

    fetch_data = instance_double(Net::IMAP::FetchData, attr: { "RFC822" => raw })

    allow(imap).to receive(:uid_search).with(["UNSEEN"]).and_return([101])
    allow(imap).to receive(:uid_fetch).with(101, ["UID", "RFC822"]).and_return([fetch_data])
    allow(imap).to receive(:uid_store).with(101, "+FLAGS", [:Seen])

    result = described_class.new(imap_client: imap).call

    expect(result.errors).to be_empty
    expect(result.files.size).to eq(1)
    expect(File.exist?(result.files.first[:path])).to eq(true)
    expect(imap).to have_received(:uid_store).with(101, "+FLAGS", [:Seen])
  end

  it "skips non-csv attachments" do
    raw = <<~MAIL
      From: ops@example.com
      To: crm@example.com
      Subject: Guests
      MIME-Version: 1.0
      Content-Type: multipart/mixed; boundary="ABC"

      --ABC
      Content-Type: application/pdf; name="doc.pdf"
      Content-Disposition: attachment; filename="doc.pdf"
      Content-Transfer-Encoding: base64

      UERG
      --ABC--
    MAIL

    fetch_data = instance_double(Net::IMAP::FetchData, attr: { "RFC822" => raw })

    allow(imap).to receive(:uid_search).and_return([201])
    allow(imap).to receive(:uid_fetch).and_return([fetch_data])
    allow(imap).to receive(:uid_store)

    result = described_class.new(imap_client: imap).call

    expect(result.files).to eq([])
    expect(result.errors).to eq([])
    expect(imap).to have_received(:uid_store).with(201, "+FLAGS", [:Seen])
  end

  it "is idempotent for duplicate attachments by deterministic filename" do
    raw = <<~MAIL
      From: ops@example.com
      To: crm@example.com
      Subject: Guests
      MIME-Version: 1.0
      Content-Type: multipart/mixed; boundary="ABC"

      --ABC
      Content-Type: text/csv; name="guests.csv"
      Content-Disposition: attachment; filename="guests.csv"
      Content-Transfer-Encoding: base64

      ZnVsbF9uYW1lLHBob25lCkpvaG4sOTk5OTk5OTk5OQ==
      --ABC--
    MAIL

    fetch_data = instance_double(Net::IMAP::FetchData, attr: { "RFC822" => raw })

    allow(imap).to receive(:uid_search).and_return([301])
    allow(imap).to receive(:uid_fetch).and_return([fetch_data])
    allow(imap).to receive(:uid_store)

    first = described_class.new(imap_client: imap).call
    second = described_class.new(imap_client: imap).call

    expect(first.files.size).to eq(1)
    expect(second.files.size).to eq(0)
  end

  it "collects message errors without marking failed messages seen" do
    raw = <<~MAIL
      From: ops@example.com
      To: crm@example.com
      Subject: Guests
      MIME-Version: 1.0
      Content-Type: multipart/mixed; boundary="ABC"

      --ABC
      Content-Type: text/csv; name="guests.csv"
      Content-Disposition: attachment; filename="guests.csv"
      Content-Transfer-Encoding: base64

      ZnVsbF9uYW1lLHBob25lCkpvaG4sOTk5OTk5OTk5OQ==
      --ABC--
    MAIL

    fetch_data = instance_double(Net::IMAP::FetchData, attr: { "RFC822" => raw })

    allow(imap).to receive(:uid_search).and_return([401, 402])
    allow(imap).to receive(:uid_fetch).with(401, ["UID", "RFC822"]).and_raise(Timeout::Error)
    allow(imap).to receive(:uid_fetch).with(402, ["UID", "RFC822"]).and_return([fetch_data])
    allow(imap).to receive(:uid_store)

    result = described_class.new(imap_client: imap).call

    expect(result.errors.size).to eq(1)
    expect(result.files.size).to eq(1)
    expect(imap).not_to have_received(:uid_store).with(401, "+FLAGS", [:Seen])
    expect(imap).to have_received(:uid_store).with(402, "+FLAGS", [:Seen])
  end
end
