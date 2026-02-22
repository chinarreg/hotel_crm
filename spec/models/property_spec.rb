require "rails_helper"

RSpec.describe Property, type: :model do
  subject(:property) { create(:property) }

  it { is_expected.to have_many(:members).dependent(:nullify) }
  it { is_expected.to have_many(:vouchers).dependent(:nullify) }
  it { is_expected.to have_many(:purchases).dependent(:nullify) }
  it { is_expected.to have_many(:guest_stays).dependent(:nullify) }
  it { is_expected.to have_many(:import_runs).dependent(:nullify) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:code) }
  it { is_expected.to validate_uniqueness_of(:code) }
end
