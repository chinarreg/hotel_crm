require "rails_helper"

RSpec.describe SendPromotionJob, type: :job do
  it "uses default queue and sends promotion template" do
    expect(described_class.sidekiq_options_hash["queue"]).to eq(:default)

    service = instance_double(WhatsappService)
    allow(WhatsappService).to receive(:new).and_return(service)
    allow(service).to receive(:send_template).and_return(WhatsappService::Result.new(success?: true, attempts: 1, status: 200))

    described_class.new.perform("9999999999", "promo_template", ["John"])

    expect(service).to have_received(:send_template).with("9999999999", "promo_template", ["John"])
  end

  it "raises when send fails" do
    service = instance_double(WhatsappService)
    allow(WhatsappService).to receive(:new).and_return(service)
    allow(service).to receive(:send_template).and_return(WhatsappService::Result.new(success?: false, attempts: 3, status: nil, error: "failed"))

    expect { described_class.new.perform("9999999999") }.to raise_error(StandardError, "failed")
  end
end
