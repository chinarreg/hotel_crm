require "rails_helper"

RSpec.describe WhatsappService, type: :service do
  let(:logger) { instance_double(Logger, info: true, error: true) }

  it "sends template successfully through injected provider" do
    provider = instance_double(Whatsapp::Providers::MetaProvider)
    allow(provider).to receive(:send_template).and_return(
      Whatsapp::Providers::BaseProvider::Result.new(success?: true, status: 200, body: "ok")
    )

    result = described_class.new(provider: provider, logger: logger).send_template("9999999999", "promo_template", ["John"])

    expect(result.success?).to eq(true)
    expect(result.attempts).to eq(1)
    expect(provider).to have_received(:send_template).with(phone: "9999999999", template_name: "promo_template", variables: ["John"])
  end

  it "retries on failure and returns graceful failure" do
    provider = instance_double(Whatsapp::Providers::MetaProvider)
    allow(provider).to receive(:send_template).and_return(
      Whatsapp::Providers::BaseProvider::Result.new(success?: false, status: 500, body: "err", error: "non_success_status"),
      Whatsapp::Providers::BaseProvider::Result.new(success?: false, status: 500, body: "err", error: "non_success_status"),
      Whatsapp::Providers::BaseProvider::Result.new(success?: false, status: 500, body: "err", error: "non_success_status")
    )

    service = described_class.new(provider: provider, logger: logger, sleep_fn: ->(_n) {})
    result = service.send_template("9999999999", "promo_template", ["John"])

    expect(result.success?).to eq(false)
    expect(result.attempts).to eq(3)
  end

  it "builds provider from AppSettings" do
    AppSetting.set("whatsapp_api_key", "api-key")
    AppSetting.set("whatsapp_phone_id", "1234")

    provider = instance_double(Whatsapp::Providers::MetaProvider)
    allow(Whatsapp::Providers::MetaProvider).to receive(:new).and_return(provider)
    allow(provider).to receive(:send_template).and_return(
      Whatsapp::Providers::BaseProvider::Result.new(success?: true, status: 200, body: "ok")
    )

    result = described_class.new(logger: logger).send_template("9999999999", "promo_template", [])

    expect(result.success?).to eq(true)
    expect(Whatsapp::Providers::MetaProvider).to have_received(:new)
  end
end
