class Voucher < ApplicationRecord
  belongs_to :property, optional: true
  belongs_to :member

  enum :status, { issued: 0, redeemed: 1, expired: 2 }, default: :issued

  validates :voucher_code, :issued_on, :expiry_date, presence: true
  validates :voucher_code, uniqueness: true
end
