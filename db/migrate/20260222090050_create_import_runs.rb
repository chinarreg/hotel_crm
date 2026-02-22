class CreateImportRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :import_runs do |t|
      t.references :property, foreign_key: true
      t.string :source_file, null: false
      t.string :source_checksum, null: false
      t.integer :status, null: false, default: 0
      t.integer :processed_rows, null: false, default: 0
      t.integer :failed_rows, null: false, default: 0
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end

    add_index :import_runs, [:property_id, :source_checksum], unique: true
    add_index :import_runs, :status
  end
end
