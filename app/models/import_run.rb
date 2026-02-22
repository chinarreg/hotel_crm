class ImportRun < ApplicationRecord
  belongs_to :property, optional: true

  enum :status, { queued: 0, processing: 1, completed: 2, failed: 3 }, default: :queued

  validates :source_file, :source_checksum, presence: true
  validates :source_checksum, uniqueness: { scope: :property_id }
end
