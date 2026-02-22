redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
redis_pool = ENV.fetch("SIDEKIQ_REDIS_POOL", "20").to_i

Sidekiq.default_job_options = { "retry" => 10, "backtrace" => true }

Sidekiq.configure_server do |config|
  config.redis = {
    url: redis_url,
    size: redis_pool,
    network_timeout: 5,
    pool_timeout: 5
  }

  config.death_handlers << lambda do |job, ex|
    Rails.logger.error({
      event: "sidekiq.dead_job",
      jid: job["jid"],
      class: job["class"],
      queue: job["queue"],
      error_class: ex.class.name,
      error_message: ex.message
    }.to_json)
  end

  config.error_handlers << lambda do |ex, ctx|
    Rails.logger.error({
      event: "sidekiq.error",
      error_class: ex.class.name,
      error_message: ex.message,
      context: ctx
    }.to_json)
  end

  schedule_file = Rails.root.join("config", "sidekiq_schedule.yml")
  if schedule_file.exist?
    Sidekiq::Cron::Job.load_from_hash(YAML.safe_load(ERB.new(File.read(schedule_file)).result) || {})
  end
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: redis_url,
    size: [redis_pool / 2, 5].max,
    network_timeout: 5,
    pool_timeout: 5
  }
end
