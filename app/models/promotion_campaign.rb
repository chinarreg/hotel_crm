class PromotionCampaign < ApplicationRecord
  belongs_to :property, optional: true
  has_many :campaign_recipients, dependent: :destroy

  enum :audience_type, { members: 0, guests: 1, custom_upload: 2 }
  enum :status, { draft: 0, queued: 1, processing: 2, completed: 3, failed: 4 }

  validates :name, :template_name, :audience_type, presence: true

  def variables
    JSON.parse(variables_json.presence || "[]")
  rescue JSON::ParserError
    []
  end

  def variables=(value)
    self.variables_json = Array(value).to_json
  end

  def recalculate_counts!
    update!(
      total_recipients: campaign_recipients.count,
      sent_count: campaign_recipients.sent.count,
      failed_count: campaign_recipients.failed.count
    )
  end
end
