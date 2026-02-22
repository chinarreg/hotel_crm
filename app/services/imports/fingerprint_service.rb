require "digest"

module Imports
  class FingerprintService
    def initialize(attrs)
      @attrs = attrs
    end

    def call
      raw = [
        @attrs[:full_name],
        @attrs[:phone],
        @attrs[:email],
        @attrs[:checkin_date],
        @attrs[:checkout_date]
      ].map { |value| value.to_s.strip.downcase }.join("|")

      Digest::SHA256.hexdigest(raw)
    end
  end
end
