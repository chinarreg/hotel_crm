require "rails_helper"

RSpec.describe CampaignRecipient, type: :model do
  subject(:recipient) { create(:campaign_recipient) }

  it { is_expected.to belong_to(:promotion_campaign) }
  it { is_expected.to validate_presence_of(:phone) }
  it { is_expected.to define_enum_for(:status).with_values(pending: 0, sent: 1, failed: 2) }
  it "validates uniqueness of phone scoped by campaign" do
    create(:campaign_recipient, promotion_campaign: recipient.promotion_campaign, phone: "9999999999")
    duplicate = build(:campaign_recipient, promotion_campaign: recipient.promotion_campaign, phone: "9999999999")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:phone]).to include("has already been taken")
  end
end
