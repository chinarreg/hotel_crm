require "rails_helper"
require "tempfile"

RSpec.describe PromotionCampaigns::BuildRecipientsService, type: :service do
  it "builds recipients from members without duplicates" do
    create(:member, phone: "9999999999", full_name: "A")
    create(:member, phone: "+91-99999-99999", full_name: "B")

    campaign = create(:promotion_campaign, audience_type: :members)

    described_class.new(campaign: campaign).call

    expect(campaign.campaign_recipients.count).to eq(1)
    expect(campaign.total_recipients).to eq(1)
  end

  it "builds recipients from custom csv upload" do
    file = Tempfile.new(["contacts", ".csv"])
    file.write("guest_name,phone\nJohn,9988776655\nJane,+91 9988776654\n")
    file.rewind

    upload = instance_double(ActionDispatch::Http::UploadedFile, original_filename: "contacts.csv", tempfile: file)
    campaign = create(:promotion_campaign, audience_type: :custom_upload)

    described_class.new(campaign: campaign, upload_io: upload).call

    expect(campaign.campaign_recipients.count).to eq(2)
    expect(campaign.campaign_recipients.pluck(:phone)).to contain_exactly("9988776655", "9988776654")
  ensure
    file.close
    file.unlink
  end
end
