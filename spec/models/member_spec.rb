require "rails_helper"

RSpec.describe Member, type: :model do
  subject(:member) { build(:member) }

  it { is_expected.to belong_to(:property).optional }
  it { is_expected.to have_many(:vouchers).dependent(:destroy) }
  it { is_expected.to have_many(:purchases).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:full_name) }
  it { is_expected.to validate_presence_of(:membership_number) }
  it { is_expected.to validate_presence_of(:membership_start_date) }
  it { is_expected.to validate_presence_of(:membership_expiry_date) }
  it { is_expected.to define_enum_for(:status).with_values(active: 0, expired: 1) }
end
