require "json"

class WhatsappService
  Result = Struct.new(:success?, :attempts, :status, :error, keyword_init: true)

  DEFAULT_RETRIES = 3

  def initialize(provider: nil, logger: Rails.logger, sleep_fn: ->(seconds) { sleep(seconds) })
    @logger = logger
    @sleep_fn = sleep_fn
    @provider = provider || build_provider
  end

  def send_template(phone, template_name, variables = [])
    attempts = 0

    begin
      attempts += 1
      provider_result = @provider.send_template(phone:, template_name:, variables:)

      if provider_result.success?
        log(:info, "whatsapp.send_template.success", phone: masked_phone(phone), template_name: template_name, attempts: attempts, status: provider_result.status)
        return Result.new(success?: true, attempts: attempts, status: provider_result.status)
      end

      raise_provider_error(provider_result)
    rescue StandardError => e
      log(:error, "whatsapp.send_template.failure", phone: masked_phone(phone), template_name: template_name, attempts: attempts, error_class: e.class.name, error_message: safe_error_message(e))

      if attempts < retry_count && retryable?(e)
        @sleep_fn.call([attempts, 3].min)
        retry
      end

      return Result.new(success?: false, attempts: attempts, status: nil, error: e.message)
    end
  end

  private

  def build_provider
    api_key = AppSetting.get("whatsapp_api_key")
    phone_id = AppSetting.get("whatsapp_phone_id")
    raise ArgumentError, "WhatsApp settings are missing" if api_key.blank? || phone_id.blank?

    case ENV.fetch("WHATSAPP_PROVIDER", "meta")
    when "meta"
      Whatsapp::Providers::MetaProvider.new(
        api_key: api_key,
        phone_id: phone_id,
        open_timeout: ENV.fetch("WHATSAPP_OPEN_TIMEOUT", "5").to_i,
        read_timeout: ENV.fetch("WHATSAPP_READ_TIMEOUT", "10").to_i,
        write_timeout: ENV.fetch("WHATSAPP_WRITE_TIMEOUT", "10").to_i
      )
    else
      raise ArgumentError, "Unsupported WhatsApp provider"
    end
  end

  def retry_count
    ENV.fetch("WHATSAPP_RETRY_COUNT", DEFAULT_RETRIES).to_i
  end

  def retryable?(error)
    return true if error.is_a?(Timeout::Error)

    message = error.message.to_s
    return true if message.include?("non_success_status")

    false
  end

  def raise_provider_error(provider_result)
    if provider_result.error.is_a?(Exception)
      raise provider_result.error
    end

    raise StandardError, provider_result.error || "whatsapp_send_failed"
  end

  def masked_phone(phone)
    digits = phone.to_s.gsub(/\D/, "")
    return "***" if digits.length < 4

    "***#{digits[-4, 4]}"
  end

  def safe_error_message(error)
    error.message.to_s.gsub(AppSetting.get("whatsapp_api_key").to_s, "[FILTERED]")
  end

  def log(level, event, payload)
    @logger.public_send(level, payload.merge(event: event, service: self.class.name).to_json)
  end
end
