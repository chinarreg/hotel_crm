require "csv"
require "digest"
require "json"

module Imports
  class CsvImportService
    BATCH_SIZE = 500

    def initialize(file_path:, property_id: nil)
      @file_path = file_path
      @property_id = property_id
      @source_file = File.basename(file_path)
      @now = Time.current
    end

    def call
      checksum = Digest::SHA256.file(file_path).hexdigest
      run = find_or_initialize_run(checksum)
      return run if run.completed?

      run.update!(status: :processing, started_at: Time.current)

      pending_rows = []
      successful_rows = 0
      failed_rows = 0

      CSV.foreach(file_path, headers: true).with_index(2) do |row, line_number|
        attrs = parse_row(row)

        if invalid_row?(attrs)
          failed_rows += 1
          log(:warn, "csv_import.bad_row", line_number: line_number, reason: "missing required fields")
          next
        end

        fingerprint = Imports::FingerprintService.new(attrs).call

        pending_rows << {
          property_id: property_id,
          full_name: attrs[:full_name],
          phone: attrs[:phone],
          email: attrs[:email],
          checkin_date: attrs[:checkin_date],
          checkout_date: attrs[:checkout_date],
          source_file: source_file,
          imported_at: now,
          row_fingerprint: fingerprint,
          created_at: now,
          updated_at: now
        }

        if pending_rows.size >= BATCH_SIZE
          successful_rows += flush_batch(pending_rows)
          pending_rows.clear
        end
      rescue StandardError => e
        failed_rows += 1
        log(:warn, "csv_import.row_error", line_number: line_number, error_class: e.class.name, error_message: e.message)
      end

      successful_rows += flush_batch(pending_rows) if pending_rows.any?

      run.update!(
        status: :completed,
        processed_rows: successful_rows,
        failed_rows: failed_rows,
        finished_at: Time.current
      )

      log(:info, "csv_import.completed", source_file: source_file, processed_rows: successful_rows, failed_rows: failed_rows)
      run
    rescue StandardError => e
      run&.update!(status: :failed, finished_at: Time.current)
      log(:error, "csv_import.failed", source_file: source_file, error_class: e.class.name, error_message: e.message)
      raise
    end

    private

    attr_reader :file_path, :property_id, :source_file, :now

    def find_or_initialize_run(checksum)
      ImportRun.find_or_create_by!(property_id: property_id, source_checksum: checksum) do |record|
        record.source_file = source_file
        record.status = :queued
      end
    end

    def flush_batch(rows)
      result = GuestStay.insert_all(rows, unique_by: :index_guest_stays_on_row_fingerprint)
      result.rows.size
    end

    def parse_row(row)
      raw = {
        full_name: fetch_field(row, mapping["full_name"]),
        phone: normalize_phone(fetch_field(row, mapping["phone"])),
        email: normalized_email(fetch_field(row, mapping["email"])),
        checkin_date: parse_date(fetch_field(row, mapping["checkin_date"])),
        checkout_date: parse_date(fetch_field(row, mapping["checkout_date"]))
      }

      raw
    end

    def invalid_row?(attrs)
      attrs[:full_name].blank? || attrs[:checkin_date].blank? || attrs[:checkout_date].blank?
    end

    def mapping
      @mapping ||= begin
        parsed = JSON.parse(AppSetting.get("csv_mapping_json", "{}"))
        {
          "full_name" => parsed["full_name"] || parsed["guest_name"] || "guest_name",
          "phone" => parsed["phone"] || "phone",
          "email" => parsed["email"] || "email",
          "checkin_date" => parsed["checkin_date"] || parsed["checkin"] || "checkin",
          "checkout_date" => parsed["checkout_date"] || parsed["checkout"] || "checkout"
        }
      rescue JSON::ParserError
        {
          "full_name" => "guest_name",
          "phone" => "phone",
          "email" => "email",
          "checkin_date" => "checkin",
          "checkout_date" => "checkout"
        }
      end
    end

    def fetch_field(row, header)
      return nil if header.blank?

      row[header] || row[header.to_s.downcase] || row[header.to_s.upcase]
    end

    def normalize_phone(phone)
      return nil if phone.blank?

      digits = phone.to_s.gsub(/\D/, "")
      return nil if digits.empty?

      digits = digits[-10, 10] if digits.length > 10
      digits
    end

    def normalized_email(email)
      return nil if email.blank?

      email.to_s.strip.downcase
    end

    def parse_date(value)
      return nil if value.blank?

      Date.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    def log(level, event, payload = {})
      Rails.logger.public_send(level, payload.merge(event: event, service: self.class.name).to_json)
    end
  end
end
