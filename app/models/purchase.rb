class Purchase < ApplicationRecord
  belongs_to :property, optional: true
  belongs_to :member

  enum :payment_mode, { cash: 0, card: 1, upi: 2, bank_transfer: 3 }, default: :cash

  validates :amount, numericality: { greater_than: 0 }
  validates :purchased_on, presence: true
end
