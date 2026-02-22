class Property < ApplicationRecord
  has_many :members, dependent: :nullify
  has_many :vouchers, dependent: :nullify
  has_many :purchases, dependent: :nullify
  has_many :guest_stays, dependent: :nullify
  has_many :import_runs, dependent: :nullify

  validates :name, :code, presence: true
  validates :code, uniqueness: true
end
