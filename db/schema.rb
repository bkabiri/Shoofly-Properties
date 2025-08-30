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

ActiveRecord::Schema[7.0].define(version: 2025_08_30_204640) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "agency_invitations", force: :cascade do |t|
    t.bigint "agency_id"
    t.string "email"
    t.string "role"
    t.string "token"
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id"], name: "index_agency_invitations_on_agency_id"
    t.index ["email"], name: "index_agency_invitations_on_email"
    t.index ["token"], name: "index_agency_invitations_on_token"
  end

  create_table "agency_memberships", force: :cascade do |t|
    t.bigint "agency_id"
    t.bigint "user_id"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id"], name: "index_agency_memberships_on_agency_id"
    t.index ["user_id"], name: "index_agency_memberships_on_user_id"
  end

  create_table "favorites", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "listing_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_id"], name: "index_favorites_on_listing_id"
    t.index ["user_id", "listing_id"], name: "index_favorites_on_user_id_and_listing_id", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "listings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "address", null: false
    t.string "place_id"
    t.integer "property_type", null: false
    t.integer "bedrooms", default: 0, null: false
    t.integer "bathrooms", default: 0, null: false
    t.decimal "size_value", precision: 10, scale: 2
    t.string "size_unit"
    t.integer "tenure", null: false
    t.integer "council_tax_band"
    t.integer "parking"
    t.boolean "garden"
    t.string "title", null: false
    t.text "description_raw", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "address_line1"
    t.string "address_line2"
    t.string "postcode"
    t.string "city"
    t.decimal "guide_price", precision: 12, scale: 2
    t.string "broadband"
    t.string "electricity_supplier"
    t.string "gas_supplier"
    t.string "slug"
    t.integer "sale_status", default: 0, null: false
    t.datetime "featured_until"
    t.integer "receptions"
    t.float "latitude"
    t.float "longitude"
    t.index ["featured_until"], name: "index_listings_on_featured_until"
    t.index ["property_type"], name: "index_listings_on_property_type"
    t.index ["sale_status"], name: "index_listings_on_sale_status"
    t.index ["slug"], name: "index_listings_on_slug", unique: true
    t.index ["status"], name: "index_listings_on_status"
    t.index ["tenure"], name: "index_listings_on_tenure"
    t.index ["user_id"], name: "index_listings_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "listing_id"
    t.bigint "plan_id", null: false
    t.string "stripe_session_id", null: false
    t.string "stripe_payment_intent_id"
    t.string "stripe_subscription_id"
    t.integer "amount_cents", null: false
    t.string "currency", null: false
    t.string "status", default: "pending", null: false
    t.jsonb "stripe_payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_id"], name: "index_payments_on_listing_id"
    t.index ["plan_id"], name: "index_payments_on_plan_id"
    t.index ["stripe_session_id"], name: "index_payments_on_stripe_session_id"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "plans", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.string "kind", null: false
    t.integer "amount_cents", null: false
    t.string "currency", default: "gbp", null: false
    t.string "interval"
    t.integer "duration_months"
    t.boolean "gives_premium", default: false
    t.integer "premium_weeks"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_plans_on_code", unique: true
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0, null: false
    t.string "office_address_line1"
    t.string "office_address_line2"
    t.string "office_postcode"
    t.string "office_city"
    t.string "office_county"
    t.string "landline_phone"
    t.string "mobile_phone"
    t.string "estate_agent_name"
    t.string "full_name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "favorites", "listings"
  add_foreign_key "favorites", "users"
  add_foreign_key "listings", "users"
  add_foreign_key "payments", "listings"
  add_foreign_key "payments", "plans"
  add_foreign_key "payments", "users"
end
