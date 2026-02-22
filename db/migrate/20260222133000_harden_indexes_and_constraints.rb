class HardenIndexesAndConstraints < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    add_index :guest_stays, :imported_at, algorithm: :concurrently, if_not_exists: true
    add_index :campaign_recipients, [:promotion_campaign_id, :status], algorithm: :concurrently, if_not_exists: true, name: "idx_campaign_recipients_campaign_status"
    add_index :promotion_campaigns, :created_at, algorithm: :concurrently, if_not_exists: true
    add_index :import_runs, :created_at, algorithm: :concurrently, if_not_exists: true

    add_check_constraint :campaign_recipients, "attempt_count >= 0", name: "chk_campaign_recipients_attempt_count_non_negative"
    add_check_constraint :promotion_campaigns, "total_recipients >= 0 AND sent_count >= 0 AND failed_count >= 0", name: "chk_promotion_campaign_counts_non_negative"
    add_check_constraint :guest_stays, "checkout_date >= checkin_date", name: "chk_guest_stays_checkout_after_checkin"

    validate_foreign_key :campaign_recipients, :promotion_campaigns
    validate_foreign_key :promotion_campaigns, :properties
    validate_foreign_key :guest_stays, :properties
    validate_foreign_key :import_runs, :properties
  end

  def down
    remove_check_constraint :guest_stays, name: "chk_guest_stays_checkout_after_checkin"
    remove_check_constraint :promotion_campaigns, name: "chk_promotion_campaign_counts_non_negative"
    remove_check_constraint :campaign_recipients, name: "chk_campaign_recipients_attempt_count_non_negative"

    remove_index :import_runs, :created_at, if_exists: true
    remove_index :promotion_campaigns, :created_at, if_exists: true
    remove_index :campaign_recipients, name: "idx_campaign_recipients_campaign_status", if_exists: true
    remove_index :guest_stays, :imported_at, if_exists: true
  end
end
