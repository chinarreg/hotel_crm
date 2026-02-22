class AppSetting < ApplicationRecord
  KEYS = %w[
    whatsapp_api_key
    whatsapp_phone_id
    imap_host
    imap_port
    imap_username
    imap_password
    imap_folder
    csv_mapping_json
  ].freeze

  SENSITIVE_KEYS = %w[whatsapp_api_key imap_password].freeze
  CACHE_NAMESPACE = "app_setting"
  WRITE_MUTEX = Mutex.new

  validates :key, presence: true, uniqueness: true, inclusion: { in: KEYS }

  class << self
    def get(key, default = nil)
      normalized_key = normalize_key(key)
      cached = Rails.cache.fetch(cache_key(normalized_key)) { uncached_get(normalized_key) }
      cached.nil? ? default : cached
    end

    def set(key, raw_value)
      normalized_key = normalize_key(key)
      value = raw_value.to_s

      WRITE_MUTEX.synchronize do
        setting = find_or_initialize_by(key: normalized_key)

        if sensitive_key?(normalized_key)
          setting.value = nil
          setting.encrypted_value = value.blank? ? nil : lockbox.encrypt(value)
        else
          setting.value = value
          setting.encrypted_value = nil
        end

        setting.save!
        Rails.cache.write(cache_key(normalized_key), value)
      end
    end

    def fetch(key, default = nil)
      get(key, default)
    end

    def masked_value_for(key)
      return nil unless sensitive_key?(key)

      current = get(key)
      current.present? ? "********" : ""
    end

    def sensitive_key?(key)
      SENSITIVE_KEYS.include?(normalize_key(key))
    end

    private

    def uncached_get(key)
      setting = find_by(key: key)
      return nil unless setting

      if sensitive_key?(key)
        return nil if setting.encrypted_value.blank?

        lockbox.decrypt(setting.encrypted_value)
      else
        setting.value
      end
    rescue Lockbox::DecryptionError
      Rails.logger.error("AppSetting decryption failed for #{key}")
      nil
    end

    def lockbox
      key = Lockbox.attribute_key(table: table_name, attribute: "encrypted_value", encode: false)
      @lockbox ||= Lockbox.new(key: key, encode: true)
    end

    def cache_key(key)
      "#{CACHE_NAMESPACE}/#{key}"
    end

    def normalize_key(key)
      normalized = key.to_s
      raise ArgumentError, "Invalid app setting key: #{normalized}" unless KEYS.include?(normalized)

      normalized
    end
  end
end
