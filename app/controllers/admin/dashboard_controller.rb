module Admin
  class DashboardController < BaseController
    def index
      @members_count = Member.count
      @active_members = Member.active.count
      @vouchers_count = Voucher.issued.count
      @imports_count = ImportRun.where("created_at >= ?", 7.days.ago).count

      @campaigns_total = PromotionCampaign.count
      @campaign_messages_sent = CampaignRecipient.sent.count
      @campaign_messages_failed = CampaignRecipient.failed.count
      @campaign_pending = CampaignRecipient.pending.count
    end
  end
end
