require "rails_helper"

RSpec.describe ImportRun, type: :model do
  subject(:import_run) { create(:import_run) }

  it { is_expected.to validate_presence_of(:source_file) }
  it { is_expected.to validate_presence_of(:source_checksum) }
  it { is_expected.to define_enum_for(:status).with_values(queued: 0, processing: 1, completed: 2, failed: 3) }

  it "validates source checksum uniqueness scoped to property" do
    create(:import_run, property: import_run.property, source_checksum: "abc")
    dup = build(:import_run, property: import_run.property, source_checksum: "abc")

    expect(dup).not_to be_valid
    expect(dup.errors[:source_checksum]).to include("has already been taken")
  end
end
