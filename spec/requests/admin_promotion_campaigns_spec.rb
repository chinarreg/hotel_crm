require "rails_helper"

RSpec.describe "Admin::PromotionCampaigns", type: :request do
  it "queues campaign and processing job" do
    allow(RuntimeMode).to receive(:background_jobs_enabled?).and_return(true)
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

  it "saves draft campaign and skips enqueue when background jobs are disabled" do
    allow(RuntimeMode).to receive(:background_jobs_enabled?).and_return(false)
    allow(RuntimeMode).to receive(:sync_processing_enabled?).and_return(false)
    allow(ProcessPromotionCampaignJob).to receive(:perform_async)

    post "/admin/promotion_campaigns", params: {
      promotion_campaign: {
        name: "Demo Campaign",
        audience_type: "members",
        template_name: "promotion_template"
      }
    }

    expect(response).to have_http_status(:redirect)
    campaign = PromotionCampaign.order(:id).last
    expect(campaign).to be_present
    expect(campaign.status).to eq("draft")
    expect(ProcessPromotionCampaignJob).not_to have_received(:perform_async)
  end

  it "processes campaign synchronously when sync mode is enabled" do
    allow(RuntimeMode).to receive(:background_jobs_enabled?).and_return(false)
    allow(RuntimeMode).to receive(:sync_processing_enabled?).and_return(true)
    job_instance = instance_double(ProcessPromotionCampaignJob)
    allow(ProcessPromotionCampaignJob).to receive(:new).and_return(job_instance)
    allow(job_instance).to receive(:perform)
    allow(ProcessPromotionCampaignJob).to receive(:perform_async)

    post "/admin/promotion_campaigns", params: {
      promotion_campaign: {
        name: "Sync Campaign",
        audience_type: "members",
        template_name: "promotion_template"
      }
    }

    expect(response).to have_http_status(:redirect)
    campaign = PromotionCampaign.order(:id).last
    expect(campaign).to be_present
    expect(campaign.status).to eq("queued")
    expect(ProcessPromotionCampaignJob).not_to have_received(:perform_async)
    expect(job_instance).to have_received(:perform).with(campaign.id)
  end

  it "returns unprocessable entity for invalid create" do
    allow(RuntimeMode).to receive(:background_jobs_enabled?).and_return(true)
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
