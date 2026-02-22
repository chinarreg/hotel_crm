class OperaCsvImportJob
  include Sidekiq::Job

  sidekiq_options queue: :low, retry: 5

  def perform(file_path, _source_file = nil, property_id = nil)
    CsvImportJob.perform_async(file_path, property_id)
  end
end
