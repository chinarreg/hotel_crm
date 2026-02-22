class CreateVouchers < ActiveRecord::Migration[8.0]
  def change
    create_table :vouchers do |t|
      t.references :property, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.string :voucher_code, null: false
      t.date :issued_on, null: false
      t.date :expiry_date, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :vouchers, :voucher_code, unique: true
    add_index :vouchers, :status
  end
end
