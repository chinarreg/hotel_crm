require "net/imap"
require "fileutils"
require "digest"
require "json"
require "timeout"
require "openssl"
require "mail"

module Imap
  class ImapFetcherService
    FetchResult = Struct.new(:files, :errors, keyword_init: true)

    TMP_DIR = Rails.root.join("tmp", "imports")
    MESSAGE_FETCH_ATTR = ["UID", "RFC822"].freeze

    def initialize(imap_client: nil, now: Time.current)
      @imap_client = imap_client
      @now = now
    end

    def call
      validate_settings!
      FileUtils.mkdir_p(TMP_DIR)

      files = []
      errors = []

      with_imap do |imap|
        unread_uids = imap.uid_search(["UNSEEN"])
        log(:info, "imap_fetch.start", unread_count: unread_uids.size, folder: settings[:folder])

        unread_uids.each do |uid|
          begin
            files.concat(process_message(imap, uid))
            mark_seen(imap, uid)
          rescue StandardError => e
            errors << { uid: uid, error: e.class.name, message: e.message }
            log(:error, "imap_fetch.message_failed", uid: uid, error_class: e.class.name, error_message: e.message)
          end
        end
      end

      log(:info, "imap_fetch.finish", saved_files: files.size, error_count: errors.size)
      FetchResult.new(files:, errors:)
    rescue Timeout::Error => e
      log(:error, "imap_fetch.timeout", error_class: e.class.name, error_message: e.message)
      raise
    rescue StandardError => e
      log(:error, "imap_fetch.failed", error_class: e.class.name, error_message: e.message)
      raise
    end

    private

    attr_reader :now

    def process_message(imap, uid)
      data = Timeout.timeout(read_timeout) { imap.uid_fetch(uid, MESSAGE_FETCH_ATTR)&.first }
      raise "IMAP fetch returned no data for UID #{uid}" if data.nil?

      raw_message = data.attr["RFC822"]
      mail = Mail.read_from_string(raw_message)
      attachments = mail.attachments

      saved = []
      attachments.each_with_index do |attachment, index|
        next unless csv_attachment?(attachment)

        decoded = attachment.decoded
        checksum = Digest::SHA256.hexdigest(decoded)
        filename = build_filename(uid:, index:, original: attachment.filename, checksum:)
        destination = TMP_DIR.join(filename)

        next if File.exist?(destination)

        File.binwrite(destination, decoded)
        saved << { path: destination.to_s, name: attachment.filename, uid: uid, checksum: checksum }
        log(:info, "imap_fetch.attachment_saved", uid: uid, file: destination.to_s, checksum: checksum)
      end

      saved
    end

    def mark_seen(imap, uid)
      Timeout.timeout(read_timeout) { imap.uid_store(uid, "+FLAGS", [:Seen]) }
      log(:info, "imap_fetch.mark_seen", uid: uid)
    end

    def csv_attachment?(attachment)
      filename = attachment.filename.to_s.downcase
      content_type = attachment.mime_type.to_s.downcase
      filename.end_with?(".csv") || content_type.include?("text/csv")
    end

    def build_filename(uid:, index:, original:, checksum:)
      clean = File.basename(original.to_s).gsub(/[^a-zA-Z0-9._-]/, "_")
      "imap_uid#{uid}_att#{index}_#{checksum[0, 12]}_#{clean}"
    end

    def with_imap
      imap = @imap_client || build_imap_client
      Timeout.timeout(open_timeout) { imap.login(settings[:username], settings[:password]) }
      Timeout.timeout(read_timeout) { imap.select(settings[:folder]) }
      yield imap
    ensure
      safely_disconnect(imap)
    end

    def build_imap_client
      ssl_options = { verify_mode: OpenSSL::SSL::VERIFY_PEER }

      Net::IMAP.new(
        settings[:host],
        port: settings[:port].to_i,
        ssl: ssl_options,
        open_timeout: open_timeout,
        read_timeout: read_timeout
      )
    end

    def safely_disconnect(imap)
      return unless imap

      imap.logout unless imap.disconnected?
      imap.disconnect unless imap.disconnected?
    rescue StandardError
      nil
    end

    def validate_settings!
      missing = %i[host port username password folder].select { |key| settings[key].blank? }
      raise ArgumentError, "Missing IMAP settings: #{missing.join(', ')}" if missing.any?
    end

    def settings
      @settings ||= {
        host: AppSetting.get("imap_host"),
        port: AppSetting.get("imap_port", "993"),
        username: AppSetting.get("imap_username"),
        password: AppSetting.get("imap_password"),
        folder: AppSetting.get("imap_folder", "INBOX")
      }
    end

    def open_timeout
      ENV.fetch("IMAP_OPEN_TIMEOUT", "10").to_i
    end

    def read_timeout
      ENV.fetch("IMAP_READ_TIMEOUT", "30").to_i
    end

    def log(level, event, payload = {})
      Rails.logger.public_send(level, payload.merge(event: event, service: self.class.name).to_json)
    end
  end
end
