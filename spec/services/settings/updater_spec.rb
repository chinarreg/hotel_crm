require "rails_helper"

RSpec.describe Settings::Updater, type: :service do
  it "does not overwrite sensitive values with blank updates" do
    AppSetting.set("imap_password", "initial-secret")

    described_class.new("imap_password" => "").call

    expect(AppSetting.get("imap_password")).to eq("initial-secret")
  end

  it "updates normal and sensitive values" do
    described_class.new("imap_host" => "imap.radisson.local", "whatsapp_api_key" => "new-key").call

    expect(AppSetting.get("imap_host")).to eq("imap.radisson.local")
    expect(AppSetting.get("whatsapp_api_key")).to eq("new-key")
  end
end
