class GuestStay < ApplicationRecord
  belongs_to :property, optional: true

  validates :full_name, :checkin_date, :checkout_date, :source_file, :imported_at, :row_fingerprint, presence: true
  validates :row_fingerprint, uniqueness: true
end
