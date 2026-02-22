require "rails_helper"

RSpec.describe ProcessPromotionCampaignJob, type: :job do
  before do
    allow_any_instance_of(ProcessPromotionCampaignJob).to receive(:sleep)
  end

  it "uses default queue, sends pending recipients and marks sent" do
    expect(described_class.sidekiq_options_hash["queue"]).to eq(:default)

    campaign = create(:promotion_campaign, status: :queued)
    recipient = create(:campaign_recipient, promotion_campaign: campaign, status: :pending, phone: "9999999999", full_name: "John")

    service = instance_double(WhatsappService)
    allow(WhatsappService).to receive(:new).and_return(service)
    allow(service).to receive(:send_template).and_return(WhatsappService::Result.new(success?: true, attempts: 1, status: 200))

    described_class.new.perform(campaign.id)

    expect(recipient.reload).to be_sent
    expect(campaign.reload).to be_completed
    expect(campaign.sent_count).to eq(1)
  end

  it "marks failed recipients and raises for retry" do
    campaign = create(:promotion_campaign, status: :queued)
    recipient = create(:campaign_recipient, promotion_campaign: campaign, status: :pending, phone: "9999999999")

    service = instance_double(WhatsappService)
    allow(WhatsappService).to receive(:new).and_return(service)
    allow(service).to receive(:send_template).and_return(WhatsappService::Result.new(success?: false, attempts: 3, status: nil, error: "provider_down"))

    expect { described_class.new.perform(campaign.id) }.to raise_error(RuntimeError, /failed recipients/)

    expect(recipient.reload).to be_failed
    expect(campaign.reload).to be_failed
  end
end
