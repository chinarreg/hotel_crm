require "csv"
require "digest"

module Imports
  class GuestImportService
    def initialize(file_path:, source_file:, property_id: nil)
      @file_path = file_path
      @source_file = source_file
      @property_id = property_id
    end

    def call
      checksum = Digest::SHA256.file(@file_path).hexdigest
      existing_run = ImportRun.find_by(property_id: @property_id, source_checksum: checksum)
      return existing_run if existing_run&.completed?

      run = existing_run || ImportRun.create!(
        property_id: @property_id,
        source_file: @source_file,
        source_checksum: checksum,
        status: :processing,
        started_at: Time.current
      )

      run.update!(status: :processing, started_at: Time.current)
      process_rows(run)
      run.update!(status: :completed, finished_at: Time.current)
      run
    rescue StandardError => e
      run&.update!(status: :failed, finished_at: Time.current)
      Rails.logger.error("Guest import failed for #{@source_file}: #{e.class} #{e.message}")
      raise
    end

    private

    def process_rows(run)
      CSV.foreach(@file_path, headers: true) do |row|
        attrs = Imports::OperaCsvParser.new(row).call
        fingerprint = Imports::FingerprintService.new(attrs).call

        GuestStay.find_or_create_by!(row_fingerprint: fingerprint) do |record|
          record.property_id = @property_id
          record.full_name = attrs[:full_name]
          record.phone = attrs[:phone]
          record.email = attrs[:email]
          record.checkin_date = attrs[:checkin_date]
          record.checkout_date = attrs[:checkout_date]
          record.source_file = @source_file
          record.imported_at = Time.current
        end

        run.increment!(:processed_rows)
      rescue StandardError => e
        run.increment!(:failed_rows)
        Rails.logger.warn("Row import failed in #{@source_file}: #{e.class} #{e.message}")
      end
    end
  end
end
