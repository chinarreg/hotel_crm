require "rails_helper"

RSpec.describe AppSetting, type: :model do
  before do
    Rails.cache.clear
  end

  it "stores whatsapp api key encrypted and reads it through get" do
    AppSetting.set("whatsapp_api_key", "secret-token")

    setting = AppSetting.find_by!(key: "whatsapp_api_key")
    expect(setting.value).to be_nil
    expect(setting.encrypted_value).to be_present
    expect(AppSetting.get("whatsapp_api_key")).to eq("secret-token")
  end

  it "stores non-sensitive values in plaintext value" do
    AppSetting.set("imap_host", "imap.example.com")

    setting = AppSetting.find_by!(key: "imap_host")
    expect(setting.value).to eq("imap.example.com")
    expect(setting.encrypted_value).to be_nil
    expect(AppSetting.get("imap_host")).to eq("imap.example.com")
  end

  it "returns cached values and refreshes cache on set" do
    AppSetting.set("imap_folder", "INBOX")
    expect(AppSetting.get("imap_folder")).to eq("INBOX")

    AppSetting.set("imap_folder", "Reservations")
    expect(AppSetting.get("imap_folder")).to eq("Reservations")
  end

  it "masks sensitive values for UI" do
    AppSetting.set("imap_password", "very-secret")

    expect(AppSetting.masked_value_for("imap_password")).to eq("********")
    expect(AppSetting.masked_value_for("imap_host")).to be_nil
  end
end
