require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module HotelCrm
  class Application < Rails::Application
    config.load_defaults 8.0
    config.autoload_lib(ignore: %w[assets tasks])

    config.active_job.queue_adapter = :sidekiq
    config.time_zone = "Asia/Kolkata"
  end
end
