module Imports
  class OperaCsvParser
    DEFAULT_MAPPING = {
      "full_name" => "full_name",
      "phone" => "phone",
      "email" => "email",
      "checkin_date" => "checkin_date",
      "checkout_date" => "checkout_date"
    }.freeze

    def initialize(row)
      @row = row
    end

    def call
      mapping = mapped_fields

      {
        full_name: fetch_field(mapping["full_name"]),
        phone: fetch_field(mapping["phone"]),
        email: fetch_field(mapping["email"]),
        checkin_date: parse_date(fetch_field(mapping["checkin_date"])),
        checkout_date: parse_date(fetch_field(mapping["checkout_date"]))
      }
    end

    private

    def mapped_fields
      raw_mapping = AppSetting.fetch("csv_mapping_json", "{}")
      parsed = JSON.parse(raw_mapping)
      DEFAULT_MAPPING.merge(parsed)
    rescue JSON::ParserError
      DEFAULT_MAPPING
    end

    def fetch_field(header)
      return nil if header.blank?

      @row[header].presence || @row[header.to_s.downcase].presence
    end

    def parse_date(value)
      return nil if value.blank?

      Date.parse(value.to_s)
    rescue ArgumentError
      nil
    end
  end
end
