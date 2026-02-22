class ImapFetchJob
  include Sidekiq::Job

  sidekiq_options queue: :low, retry: 10, backtrace: true

  def perform(property_id = nil)
    result = Imap::ImapFetcherService.new.call

    result.files.each do |file_info|
      CsvImportJob.perform_async(file_info[:path], property_id)
    end

    raise "IMAP fetch completed with #{result.errors.size} failed messages" if result.errors.any?
  rescue StandardError => e
    Rails.logger.error({
      event: "imap_fetch_job.failed",
      job: self.class.name,
      error_class: e.class.name,
      error_message: e.message
    }.to_json)
    raise
  end
end
