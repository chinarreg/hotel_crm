class ProcessPromotionCampaignJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 8, backtrace: true

  def perform(campaign_id)
    campaign = PromotionCampaign.find(campaign_id)
    campaign.update!(status: :processing, started_at: Time.current)

    service = WhatsappService.new
    interval = 60.0 / rate_limit_per_minute

    campaign.campaign_recipients.pending.order(:id).find_each do |recipient|
      result = service.send_template(
        recipient.phone,
        campaign.template_name,
        build_variables(campaign, recipient)
      )

      if result.success?
        recipient.update!(status: :sent, sent_at: Time.current, attempt_count: recipient.attempt_count + 1, last_error: nil)
      else
        recipient.update!(status: :failed, attempt_count: recipient.attempt_count + 1, last_error: result.error)
      end

      sleep(interval) if interval.positive?
    rescue StandardError => e
      recipient.update_columns(
        status: CampaignRecipient.statuses[:failed],
        attempt_count: recipient.attempt_count + 1,
        last_error: e.message,
        updated_at: Time.current
      )
      Rails.logger.error({
        event: "promotion_campaign.recipient_error",
        campaign_id: campaign.id,
        recipient_id: recipient.id,
        error_class: e.class.name,
        error_message: e.message
      }.to_json)
    end

    campaign.recalculate_counts!
    campaign.update!(status: :completed, finished_at: Time.current)

    raise "Campaign has failed recipients" if campaign.campaign_recipients.failed.exists?
  rescue StandardError => e
    campaign&.update!(status: :failed, finished_at: Time.current, last_error: e.message)
    Rails.logger.error({
      event: "promotion_campaign.failed",
      campaign_id: campaign&.id,
      error_class: e.class.name,
      error_message: e.message
    }.to_json)
    raise
  end

  private

  def rate_limit_per_minute
    ENV.fetch("WHATSAPP_RATE_LIMIT_PER_MINUTE", "60").to_i.clamp(1, 600)
  end

  def build_variables(campaign, recipient)
    campaign.variables.map do |value|
      value.to_s
           .gsub("{{name}}", recipient.full_name.to_s)
           .gsub("{{phone}}", recipient.phone.to_s)
    end
  end
end
