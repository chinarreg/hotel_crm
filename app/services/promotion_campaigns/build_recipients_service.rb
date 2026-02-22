require "csv"
require "roo"

module PromotionCampaigns
  class BuildRecipientsService
    def initialize(campaign:, upload_io: nil)
      @campaign = campaign
      @upload_io = upload_io
      @rows = []
    end

    def call
      collect_rows
      insert_rows
      campaign.recalculate_counts!
      campaign
    end

    private

    attr_reader :campaign, :upload_io, :rows

    def collect_rows
      case campaign.audience_type
      when "members"
        Member.where.not(phone: [nil, ""]).find_each do |member|
          rows << recipient_hash(phone: normalize_phone(member.phone), full_name: member.full_name, source_type: "member", source_id: member.id)
        end
      when "guests"
        GuestStay.where.not(phone: [nil, ""]).find_each do |guest|
          rows << recipient_hash(phone: normalize_phone(guest.phone), full_name: guest.full_name, source_type: "guest", source_id: guest.id)
        end
      when "custom_upload"
        raise ArgumentError, "Upload file is required for custom audience" unless upload_io

        parse_upload.each do |entry|
          rows << recipient_hash(phone: normalize_phone(entry[:phone]), full_name: entry[:full_name], source_type: "custom", source_id: nil)
        end
      end

      rows.select! { |row| row[:phone].present? }
      rows.uniq! { |row| row[:phone] }
    end

    def insert_rows
      return if rows.empty?

      CampaignRecipient.insert_all(rows, unique_by: :idx_campaign_recipients_campaign_phone)
    end

    def recipient_hash(phone:, full_name:, source_type:, source_id:)
      {
        promotion_campaign_id: campaign.id,
        phone: phone,
        full_name: full_name,
        source_type: source_type,
        source_id: source_id,
        status: CampaignRecipient.statuses[:pending],
        attempt_count: 0,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    def parse_upload
      ext = File.extname(upload_io.original_filename.to_s).downcase
      case ext
      when ".csv"
        parse_csv(upload_io.tempfile.path)
      when ".xlsx", ".xls"
        parse_spreadsheet(upload_io.tempfile.path)
      else
        raise ArgumentError, "Unsupported file format. Upload CSV or Excel"
      end
    end

    def parse_csv(path)
      CSV.foreach(path, headers: true).map do |row|
        {
          full_name: row["guest_name"] || row["name"] || row["full_name"],
          phone: row["phone"]
        }
      end
    end

    def parse_spreadsheet(path)
      sheet = Roo::Spreadsheet.open(path).sheet(0)
      headers = sheet.row(1).map { |h| h.to_s.strip.downcase }

      (2..sheet.last_row).map do |row_number|
        values = sheet.row(row_number)
        indexed = headers.zip(values).to_h
        {
          full_name: indexed["guest_name"] || indexed["name"] || indexed["full_name"],
          phone: indexed["phone"]
        }
      end
    end

    def normalize_phone(phone)
      return nil if phone.blank?

      digits = phone.to_s.gsub(/\D/, "")
      return nil if digits.empty?

      digits.length > 10 ? digits[-10, 10] : digits
    end
  end
end
