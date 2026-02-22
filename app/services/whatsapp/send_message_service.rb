module Whatsapp
  class SendMessageService
    def initialize(phone:, message:)
      @phone = phone
      @message = message
    end

    def call
      api_key = Settings::Fetcher.new("whatsapp_api_key").call
      phone_id = Settings::Fetcher.new("whatsapp_phone_id").call
      raise ArgumentError, "WhatsApp settings are missing" if api_key.blank? || phone_id.blank?

      Rails.logger.info("Stub WhatsApp send to #{@phone} via phone_id=#{phone_id}")
      true
    end
  end
end
