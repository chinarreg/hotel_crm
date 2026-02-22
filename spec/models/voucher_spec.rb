require "rails_helper"

RSpec.describe Voucher, type: :model do
  subject(:voucher) { create(:voucher) }

  it { is_expected.to belong_to(:member) }
  it { is_expected.to validate_presence_of(:voucher_code) }
  it { is_expected.to validate_uniqueness_of(:voucher_code) }
  it { is_expected.to define_enum_for(:status).with_values(issued: 0, redeemed: 1, expired: 2) }
end
