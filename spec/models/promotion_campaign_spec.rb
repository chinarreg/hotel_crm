require "rails_helper"

RSpec.describe PromotionCampaign, type: :model do
  it { is_expected.to have_many(:campaign_recipients).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:template_name) }
  it { is_expected.to define_enum_for(:audience_type).with_values(members: 0, guests: 1, custom_upload: 2) }
  it { is_expected.to define_enum_for(:status).with_values(draft: 0, queued: 1, processing: 2, completed: 3, failed: 4) }
end
