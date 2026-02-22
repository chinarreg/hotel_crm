# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_02_22_133000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "app_settings", force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "encrypted_value"
    t.index ["key"], name: "index_app_settings_on_key", unique: true
  end

  create_table "campaign_recipients", force: :cascade do |t|
    t.bigint "promotion_campaign_id", null: false
    t.string "phone", null: false
    t.string "full_name"
    t.string "source_type", null: false
    t.bigint "source_id"
    t.integer "status", default: 0, null: false
    t.integer "attempt_count", default: 0, null: false
    t.datetime "sent_at"
    t.text "last_error"
    t.text "metadata_json"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["promotion_campaign_id", "phone"], name: "idx_campaign_recipients_campaign_phone", unique: true
    t.index ["promotion_campaign_id", "status"], name: "idx_campaign_recipients_campaign_status"
    t.index ["promotion_campaign_id"], name: "index_campaign_recipients_on_promotion_campaign_id"
    t.index ["source_type", "source_id"], name: "index_campaign_recipients_on_source_type_and_source_id"
    t.index ["status"], name: "index_campaign_recipients_on_status"
    t.check_constraint "attempt_count >= 0", name: "chk_campaign_recipients_attempt_count_non_negative"
  end

  create_table "guest_stays", force: :cascade do |t|
    t.bigint "property_id"
    t.string "full_name", null: false
    t.string "phone"
    t.string "email"
    t.date "checkin_date", null: false
    t.date "checkout_date", null: false
    t.string "source_file", null: false
    t.datetime "imported_at", null: false
    t.string "row_fingerprint", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checkin_date"], name: "index_guest_stays_on_checkin_date"
    t.index ["email"], name: "index_guest_stays_on_email"
    t.index ["imported_at"], name: "index_guest_stays_on_imported_at"
    t.index ["phone"], name: "index_guest_stays_on_phone"
    t.index ["property_id"], name: "index_guest_stays_on_property_id"
    t.index ["row_fingerprint"], name: "index_guest_stays_on_row_fingerprint", unique: true
    t.check_constraint "checkout_date >= checkin_date", name: "chk_guest_stays_checkout_after_checkin"
  end

  create_table "import_runs", force: :cascade do |t|
    t.bigint "property_id"
    t.string "source_file", null: false
    t.string "source_checksum", null: false
    t.integer "status", default: 0, null: false
    t.integer "processed_rows", default: 0, null: false
    t.integer "failed_rows", default: 0, null: false
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_import_runs_on_created_at"
    t.index ["property_id", "source_checksum"], name: "index_import_runs_on_property_id_and_source_checksum", unique: true
    t.index ["property_id"], name: "index_import_runs_on_property_id"
    t.index ["status"], name: "index_import_runs_on_status"
  end

  create_table "members", force: :cascade do |t|
    t.bigint "property_id"
    t.string "full_name", null: false
    t.string "phone"
    t.string "email"
    t.string "membership_number", null: false
    t.date "membership_start_date", null: false
    t.date "membership_expiry_date", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_members_on_email"
    t.index ["membership_number"], name: "index_members_on_membership_number", unique: true
    t.index ["phone"], name: "index_members_on_phone"
    t.index ["property_id"], name: "index_members_on_property_id"
  end

  create_table "promotion_campaigns", force: :cascade do |t|
    t.bigint "property_id"
    t.string "name", null: false
    t.integer "audience_type", null: false
    t.string "template_name", null: false
    t.text "variables_json"
    t.string "source_file"
    t.integer "status", default: 0, null: false
    t.integer "total_recipients", default: 0, null: false
    t.integer "sent_count", default: 0, null: false
    t.integer "failed_count", default: 0, null: false
    t.datetime "started_at"
    t.datetime "finished_at"
    t.text "last_error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["audience_type"], name: "index_promotion_campaigns_on_audience_type"
    t.index ["created_at"], name: "index_promotion_campaigns_on_created_at"
    t.index ["property_id"], name: "index_promotion_campaigns_on_property_id"
    t.index ["status"], name: "index_promotion_campaigns_on_status"
    t.check_constraint "total_recipients >= 0 AND sent_count >= 0 AND failed_count >= 0", name: "chk_promotion_campaign_counts_non_negative"
  end

  create_table "properties", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_properties_on_code", unique: true
  end

  create_table "purchases", force: :cascade do |t|
    t.bigint "property_id"
    t.bigint "member_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.date "purchased_on", null: false
    t.integer "payment_mode", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_purchases_on_member_id"
    t.index ["payment_mode"], name: "index_purchases_on_payment_mode"
    t.index ["property_id"], name: "index_purchases_on_property_id"
    t.index ["purchased_on"], name: "index_purchases_on_purchased_on"
  end

  create_table "vouchers", force: :cascade do |t|
    t.bigint "property_id"
    t.bigint "member_id", null: false
    t.string "voucher_code", null: false
    t.date "issued_on", null: false
    t.date "expiry_date", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_vouchers_on_member_id"
    t.index ["property_id"], name: "index_vouchers_on_property_id"
    t.index ["status"], name: "index_vouchers_on_status"
    t.index ["voucher_code"], name: "index_vouchers_on_voucher_code", unique: true
  end

  add_foreign_key "campaign_recipients", "promotion_campaigns"
  add_foreign_key "guest_stays", "properties"
  add_foreign_key "import_runs", "properties"
  add_foreign_key "members", "properties"
  add_foreign_key "promotion_campaigns", "properties"
  add_foreign_key "purchases", "members"
  add_foreign_key "purchases", "properties"
  add_foreign_key "vouchers", "members"
  add_foreign_key "vouchers", "properties"
end
