class CreateGuestStays < ActiveRecord::Migration[8.0]
  def change
    create_table :guest_stays do |t|
      t.references :property, foreign_key: true
      t.string :full_name, null: false
      t.string :phone
      t.string :email
      t.date :checkin_date, null: false
      t.date :checkout_date, null: false
      t.string :source_file, null: false
      t.datetime :imported_at, null: false
      t.string :row_fingerprint, null: false

      t.timestamps
    end

    add_index :guest_stays, :phone
    add_index :guest_stays, :email
    add_index :guest_stays, :checkin_date
    add_index :guest_stays, :row_fingerprint, unique: true
  end
end
