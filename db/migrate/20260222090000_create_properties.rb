class CreateProperties < ActiveRecord::Migration[8.0]
  def change
    create_table :properties do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :properties, :code, unique: true
  end
end
