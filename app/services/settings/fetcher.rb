module Settings
  class Fetcher
    def initialize(key)
      @key = key.to_s
    end

    def call(default: nil)
      AppSetting.get(@key, default)
    end
  end
end
