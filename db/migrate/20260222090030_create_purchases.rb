class CreatePurchases < ActiveRecord::Migration[8.0]
  def change
    create_table :purchases do |t|
      t.references :property, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.date :purchased_on, null: false
      t.integer :payment_mode, null: false, default: 0

      t.timestamps
    end

    add_index :purchases, :purchased_on
    add_index :purchases, :payment_mode
  end
end
