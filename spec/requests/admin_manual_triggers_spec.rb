require "rails_helper"

RSpec.describe "Admin manual triggers", type: :request do
  describe "POST /admin/import_runs/trigger_imap" do
    it "queues imap fetch when background jobs are enabled" do
      allow(RuntimeMode).to receive(:background_jobs_enabled?).and_return(true)
      allow(ImapFetchJob).to receive(:perform_async)

      post "/admin/import_runs/trigger_imap"

      expect(response).to redirect_to(admin_import_runs_path)
      expect(ImapFetchJob).to have_received(:perform_async)
    end

    it "runs imap and csv import synchronously when sync mode is enabled" do
      allow(RuntimeMode).to receive(:background_jobs_enabled?).and_return(false)
      allow(RuntimeMode).to receive(:sync_processing_enabled?).and_return(true)

      fetcher = instance_double(Imap::ImapFetcherService)
      result = Imap::ImapFetcherService::FetchResult.new(files: [{ path: "/tmp/imports/a.csv" }], errors: [])
      allow(Imap::ImapFetcherService).to receive(:new).and_return(fetcher)
      allow(fetcher).to receive(:call).and_return(result)

      importer = instance_double(Imports::CsvImportService)
      allow(Imports::CsvImportService).to receive(:new).with(file_path: "/tmp/imports/a.csv").and_return(importer)
      allow(importer).to receive(:call)

      post "/admin/import_runs/trigger_imap"

      expect(response).to redirect_to(admin_import_runs_path)
      expect(importer).to have_received(:call)
    end

    it "shows alert when both background and sync modes are disabled" do
      allow(RuntimeMode).to receive(:background_jobs_enabled?).and_return(false)
      allow(RuntimeMode).to receive(:sync_processing_enabled?).and_return(false)

      post "/admin/import_runs/trigger_imap"

      expect(response).to redirect_to(admin_import_runs_path)
    end
  end

  describe "POST /admin/promotion_campaigns/:id/process_now" do
    let(:campaign) { create(:promotion_campaign) }

    it "queues processing when background jobs are enabled" do
      allow(RuntimeMode).to receive(:background_jobs_enabled?).and_return(true)
      allow(ProcessPromotionCampaignJob).to receive(:perform_async)

      post "/admin/promotion_campaigns/#{campaign.id}/process_now"

      expect(response).to redirect_to(admin_promotion_campaign_path(campaign))
      expect(ProcessPromotionCampaignJob).to have_received(:perform_async).with(campaign.id)
    end

    it "processes synchronously when sync mode is enabled" do
      allow(RuntimeMode).to receive(:background_jobs_enabled?).and_return(false)
      allow(RuntimeMode).to receive(:sync_processing_enabled?).and_return(true)
      job_instance = instance_double(ProcessPromotionCampaignJob)
      allow(ProcessPromotionCampaignJob).to receive(:new).and_return(job_instance)
      allow(job_instance).to receive(:perform)

      post "/admin/promotion_campaigns/#{campaign.id}/process_now"

      expect(response).to redirect_to(admin_promotion_campaign_path(campaign))
      expect(job_instance).to have_received(:perform).with(campaign.id)
    end

    it "shows alert when both background and sync modes are disabled" do
      allow(RuntimeMode).to receive(:background_jobs_enabled?).and_return(false)
      allow(RuntimeMode).to receive(:sync_processing_enabled?).and_return(false)

      post "/admin/promotion_campaigns/#{campaign.id}/process_now"

      expect(response).to redirect_to(admin_promotion_campaign_path(campaign))
    end
  end
end
