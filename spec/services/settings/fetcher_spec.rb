require "rails_helper"

RSpec.describe Settings::Fetcher, type: :service do
  it "returns configured value" do
    AppSetting.set("imap_host", "imap.acme.test")

    value = described_class.new("imap_host").call

    expect(value).to eq("imap.acme.test")
  end

  it "returns default when missing" do
    value = described_class.new("imap_username").call(default: "fallback")

    expect(value).to eq("fallback")
  end
end
