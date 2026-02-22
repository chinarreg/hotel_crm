module RuntimeMode
  module_function

  def background_jobs_enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("BACKGROUND_JOBS_ENABLED", "true"))
  end

  def sync_processing_enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("SYNC_PROCESSING", "false"))
  end
end
