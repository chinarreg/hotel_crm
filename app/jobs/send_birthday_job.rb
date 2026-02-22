class SendBirthdayJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 5

  def perform(phone, variables = [])
    result = WhatsappService.new.send_template(phone, "birthday_template", variables)
    raise StandardError, result.error unless result.success?
  end
end
