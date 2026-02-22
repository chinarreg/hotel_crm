require "rails_helper"

RSpec.describe "Admin::PromotionCampaigns", type: :request do
  it "queues campaign and processing job" do
    allow(ProcessPromotionCampaignJob).to receive(:perform_async)

    post "/admin/promotion_campaigns", params: {
      promotion_campaign: {
        name: "Festive Promo",
        audience_type: "members",
        template_name: "promotion_template",
        variables_input: "Hello {{name}}"
      }
    }

    expect(response).to have_http_status(:redirect)
    campaign = PromotionCampaign.order(:id).last
    expect(campaign).to be_present
    expect(ProcessPromotionCampaignJob).to have_received(:perform_async).with(campaign.id)
  end

  it "returns unprocessable entity for invalid create" do
    post "/admin/promotion_campaigns", params: {
      promotion_campaign: {
        name: "",
        audience_type: "members",
        template_name: ""
      }
    }

    expect(response).to have_http_status(:unprocessable_entity)
  end
end
