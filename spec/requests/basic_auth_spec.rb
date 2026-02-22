require "rails_helper"

RSpec.describe "BasicAuth", type: :request do
  around do |example|
    original_username = ENV["BASIC_AUTH_USERNAME"]
    original_password = ENV["BASIC_AUTH_PASSWORD"]

    ENV["BASIC_AUTH_USERNAME"] = "demo"
    ENV["BASIC_AUTH_PASSWORD"] = "secret123"

    example.run
  ensure
    ENV["BASIC_AUTH_USERNAME"] = original_username
    ENV["BASIC_AUTH_PASSWORD"] = original_password
  end

  it "blocks admin pages without credentials" do
    get "/admin"

    expect(response).to have_http_status(:unauthorized)
  end

  it "allows admin pages with valid credentials" do
    get "/admin", headers: { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("demo", "secret123") }

    expect(response).to have_http_status(:ok)
  end
end
