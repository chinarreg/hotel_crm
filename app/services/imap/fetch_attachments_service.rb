require "net/imap"
require "fileutils"
require "mail"

module Imap
  class FetchAttachmentsService
    TMP_DIR = Rails.root.join("tmp", "imports")

    def call
      FileUtils.mkdir_p(TMP_DIR)
      attachments = []

      imap = Net::IMAP.new(settings.fetch(:host), settings.fetch(:port).to_i, true)
      imap.login(settings.fetch(:username), settings.fetch(:password))
      imap.select(settings.fetch(:folder))

      message_ids = imap.search(["UNSEEN"])
      message_ids.each do |message_id|
        data = imap.fetch(message_id, "RFC822").first
        mail = Mail.read_from_string(data.attr["RFC822"])

        mail.attachments.each do |attachment|
          next unless attachment.filename&.downcase&.end_with?(".csv")

          file_path = TMP_DIR.join("#{Time.current.to_i}_#{attachment.filename}")
          File.binwrite(file_path, attachment.decoded)
          attachments << { path: file_path.to_s, name: attachment.filename }
        end
      end

      attachments
    ensure
      imap&.logout
      imap&.disconnect
    end

    private

    def settings
      {
        host: Settings::Fetcher.new("imap_host").call,
        port: Settings::Fetcher.new("imap_port").call(default: "993"),
        username: Settings::Fetcher.new("imap_username").call,
        password: Settings::Fetcher.new("imap_password").call,
        folder: Settings::Fetcher.new("imap_folder").call(default: "INBOX")
      }
    end
  end
end
