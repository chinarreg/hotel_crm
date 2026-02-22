class SendPromotionJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 5

  def perform(phone, template_name = "promotion_template", variables = [])
    result = WhatsappService.new.send_template(phone, template_name, variables)
    raise StandardError, result.error unless result.success?
  end
end
