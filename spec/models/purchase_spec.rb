require "rails_helper"

RSpec.describe Purchase, type: :model do
  it { is_expected.to belong_to(:member) }
  it { is_expected.to validate_presence_of(:purchased_on) }
  it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }
  it { is_expected.to define_enum_for(:payment_mode).with_values(cash: 0, card: 1, upi: 2, bank_transfer: 3) }
end
