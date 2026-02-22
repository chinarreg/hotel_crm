require "rails_helper"

RSpec.describe "Health", type: :request do
  it "returns sidekiq health ok" do
    allow(RuntimeMode).to receive(:background_jobs_enabled?).and_return(true)
    stub_const("Sidekiq::Queue", Class.new do
      def initialize(*); end
      def latency = 0.12
    end)

    allow(Sidekiq).to receive(:redis).and_yield(instance_double("RedisConn", ping: "PONG"))
    allow(Sidekiq::Queue).to receive(:new).with("default").and_return(instance_double("SidekiqQueue", latency: 0.12))

    get "/health/sidekiq"

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["status"]).to eq("ok")
  end

  it "returns disabled when background jobs are turned off" do
    allow(RuntimeMode).to receive(:background_jobs_enabled?).and_return(false)

    get "/health/sidekiq"

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["status"]).to eq("disabled")
  end
end
