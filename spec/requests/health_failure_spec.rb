require "rails_helper"

RSpec.describe "HealthFailure", type: :request do
  it "returns service unavailable when redis check fails" do
    allow(Sidekiq).to receive(:redis).and_raise(StandardError.new("redis unavailable"))

    get "/health/sidekiq"

    expect(response).to have_http_status(:service_unavailable)
    expect(JSON.parse(response.body)["status"]).to eq("error")
  end
end
