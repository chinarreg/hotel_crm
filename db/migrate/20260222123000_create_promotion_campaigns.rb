class CreatePromotionCampaigns < ActiveRecord::Migration[8.0]
  def change
    create_table :promotion_campaigns do |t|
      t.references :property, foreign_key: true
      t.string :name, null: false
      t.integer :audience_type, null: false
      t.string :template_name, null: false
      t.text :variables_json
      t.string :source_file
      t.integer :status, null: false, default: 0
      t.integer :total_recipients, null: false, default: 0
      t.integer :sent_count, null: false, default: 0
      t.integer :failed_count, null: false, default: 0
      t.datetime :started_at
      t.datetime :finished_at
      t.text :last_error

      t.timestamps
    end

    add_index :promotion_campaigns, :status
    add_index :promotion_campaigns, :audience_type
  end
end
