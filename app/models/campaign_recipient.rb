class CampaignRecipient < ApplicationRecord
  belongs_to :promotion_campaign

  enum :status, { pending: 0, sent: 1, failed: 2 }

  validates :phone, :source_type, presence: true
  validates :phone, uniqueness: { scope: :promotion_campaign_id }

  def metadata
    JSON.parse(metadata_json.presence || "{}")
  rescue JSON::ParserError
    {}
  end

  def metadata=(value)
    self.metadata_json = value.to_json
  end
end
