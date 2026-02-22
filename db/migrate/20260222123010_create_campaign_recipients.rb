class CreateCampaignRecipients < ActiveRecord::Migration[8.0]
  def change
    create_table :campaign_recipients do |t|
      t.references :promotion_campaign, null: false, foreign_key: true
      t.string :phone, null: false
      t.string :full_name
      t.string :source_type, null: false
      t.bigint :source_id
      t.integer :status, null: false, default: 0
      t.integer :attempt_count, null: false, default: 0
      t.datetime :sent_at
      t.text :last_error
      t.text :metadata_json

      t.timestamps
    end

    add_index :campaign_recipients, [:promotion_campaign_id, :phone], unique: true, name: "idx_campaign_recipients_campaign_phone"
    add_index :campaign_recipients, :status
    add_index :campaign_recipients, [:source_type, :source_id]
  end
end
