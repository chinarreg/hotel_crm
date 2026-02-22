require "rails_helper"

RSpec.describe GuestStay, type: :model do
  subject(:guest_stay) { create(:guest_stay) }

  it { is_expected.to validate_presence_of(:full_name) }
  it { is_expected.to validate_presence_of(:checkin_date) }
  it { is_expected.to validate_presence_of(:checkout_date) }
  it { is_expected.to validate_presence_of(:source_file) }
  it { is_expected.to validate_presence_of(:imported_at) }
  it { is_expected.to validate_presence_of(:row_fingerprint) }
  it { is_expected.to validate_uniqueness_of(:row_fingerprint) }
end
