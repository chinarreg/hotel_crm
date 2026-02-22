class Member < ApplicationRecord
  belongs_to :property, optional: true
  has_many :vouchers, dependent: :destroy
  has_many :purchases, dependent: :destroy

  enum :status, { active: 0, expired: 1 }, default: :active

  validates :full_name, :membership_number, :membership_start_date, :membership_expiry_date, presence: true
  validates :membership_number, uniqueness: true
  validates :phone, uniqueness: true, allow_blank: true
  validates :email, uniqueness: true, allow_blank: true
end
