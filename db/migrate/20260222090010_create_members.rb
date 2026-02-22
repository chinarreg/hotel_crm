class CreateMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :members do |t|
      t.references :property, foreign_key: true
      t.string :full_name, null: false
      t.string :phone
      t.string :email
      t.string :membership_number, null: false
      t.date :membership_start_date, null: false
      t.date :membership_expiry_date, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :members, :membership_number, unique: true
    add_index :members, :phone
    add_index :members, :email
  end
end
