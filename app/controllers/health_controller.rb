require "sidekiq/api"

class HealthController < ActionController::API
  def sidekiq
    redis_info = Sidekiq.redis { |conn| conn.ping }
    latency = Sidekiq::Queue.new("default").latency

    render json: {
      status: "ok",
      redis: redis_info,
      default_queue_latency_seconds: latency.round(3),
      timestamp: Time.current.utc.iso8601
    }
  rescue StandardError => e
    render json: { status: "error", error: e.message }, status: :service_unavailable
  end
end
