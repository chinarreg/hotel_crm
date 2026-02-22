require "rails_helper"

RSpec.describe "Admin::Members", type: :request do
  it "supports query search" do
    create(:member, full_name: "Alpha User", membership_number: "RBM-1001", phone: "9000000001")
    create(:member, full_name: "Beta User", membership_number: "RBM-1002", phone: "9000000002")

    get "/admin/members", params: { q: "Alpha" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Alpha User")
    expect(response.body).not_to include("Beta User")
  end

  it "supports status filter" do
    create(:member, status: :active, membership_number: "RBM-2001")
    create(:member, status: :expired, membership_number: "RBM-2002")

    get "/admin/members", params: { status: "expired" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("expired")
  end
end
