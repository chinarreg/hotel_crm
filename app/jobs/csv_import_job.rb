class CsvImportJob
  include Sidekiq::Job

  sidekiq_options queue: :low, retry: 7, backtrace: true

  def perform(file_path, property_id = nil)
    Imports::CsvImportService.new(file_path:, property_id:).call
  rescue StandardError => e
    Rails.logger.error({
      event: "csv_import_job.failed",
      job: self.class.name,
      file_path: file_path,
      error_class: e.class.name,
      error_message: e.message
    }.to_json)
    raise
  end
end
