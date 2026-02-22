module Settings
  class Updater
    def initialize(params)
      @params = params
    end

    def call
      AppSetting.transaction do
        @params.each do |key, value|
          next unless AppSetting::KEYS.include?(key.to_s)
          next if skip_sensitive_blank?(key, value)

          AppSetting.set(key, value)
        end
      end
    end

    private

    def skip_sensitive_blank?(key, value)
      AppSetting.sensitive_key?(key) && value.blank?
    end
  end
end
