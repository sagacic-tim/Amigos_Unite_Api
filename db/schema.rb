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

ActiveRecord::Schema[7.0].define(version: 2023_11_23_043125) do
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

  create_table "amigo_details", force: :cascade do |t|
    t.date "date_of_birth"
    t.boolean "member_in_good_standing"
    t.boolean "available_to_host"
    t.boolean "willing_to_help"
    t.boolean "willing_to_donate"
    t.text "personal_bio"
    t.bigint "amigo_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["amigo_id"], name: "index_amigo_details_on_amigo_id"
  end

  create_table "amigo_locations", force: :cascade do |t|
    t.bigint "amigo_id", null: false
    t.string "address", limit: 256
    t.string "address_type", limit: 12
    t.string "floor", limit: 10
    t.string "building", limit: 16
    t.string "street_predirection", limit: 16
    t.string "street_number", limit: 30
    t.string "street_name", limit: 64
    t.string "street_postdirection", limit: 16
    t.string "street_suffix", limit: 16
    t.string "apartment_suite_number", limit: 32
    t.string "city", limit: 64
    t.string "county", limit: 64
    t.string "state_abbreviation", limit: 2
    t.string "country_code", limit: 5
    t.string "postal_code", limit: 12
    t.string "plus4_code", limit: 4
    t.decimal "latitude", precision: 9, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.string "time_zone", limit: 48
    t.string "congressional_district", limit: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["amigo_id"], name: "index_amigo_locations_on_amigo_id"
  end

  create_table "amigos", force: :cascade do |t|
    t.string "first_name", limit: 50
    t.string "last_name", limit: 50
    t.string "user_name", limit: 50, default: "", null: false
    t.string "email", limit: 50, default: "", null: false
    t.string "secondary_email", limit: 50, default: ""
    t.string "phone_1", limit: 20
    t.string "phone_2", limit: 20
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "jti", null: false
    t.index ["confirmation_token"], name: "index_amigos_on_confirmation_token", unique: true
    t.index ["email"], name: "index_amigos_on_email", unique: true
    t.index ["jti"], name: "index_amigos_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_amigos_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_amigos_on_unlock_token", unique: true
    t.index ["user_name"], name: "index_amigos_on_user_name", unique: true
  end

  create_table "event_coordinators", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "amigo_id", null: false
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["amigo_id"], name: "index_event_coordinators_on_amigo_id"
    t.index ["event_id"], name: "index_event_coordinators_on_event_id"
  end

  create_table "event_locations", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.string "address", limit: 256
    t.string "address_type", limit: 12
    t.string "floor", limit: 10
    t.string "building", limit: 16
    t.string "street_predirection", limit: 16
    t.string "street_number", limit: 30
    t.string "street_name", limit: 64
    t.string "street_postdirection", limit: 16
    t.string "street_suffix", limit: 16
    t.string "apartment_suite_number", limit: 32
    t.string "city", limit: 64
    t.string "county", limit: 64
    t.string "state_abbreviation", limit: 2
    t.string "country_code", limit: 5
    t.string "postal_code", limit: 12
    t.string "plus4_code", limit: 4
    t.decimal "latitude", precision: 9, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.string "time_zone", limit: 48
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_event_locations_on_event_id"
  end

  create_table "event_participants", force: :cascade do |t|
    t.bigint "amigo_id", null: false
    t.bigint "event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["amigo_id"], name: "index_event_participants_on_amigo_id"
    t.index ["event_id"], name: "index_event_participants_on_event_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "event_name"
    t.string "event_type"
    t.string "event_speakers_performers", default: [], array: true
    t.date "event_date"
    t.datetime "event_time"
    t.bigint "event_location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_location_id"], name: "index_events_on_event_location_id"
  end

  create_table "login_activities", force: :cascade do |t|
    t.string "scope"
    t.string "strategy"
    t.string "identity"
    t.boolean "success"
    t.string "failure_reason"
    t.string "user_type"
    t.bigint "user_id"
    t.string "context"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "city"
    t.string "region"
    t.string "country"
    t.float "latitude"
    t.float "longitude"
    t.datetime "created_at"
    t.index ["identity"], name: "index_login_activities_on_identity"
    t.index ["ip"], name: "index_login_activities_on_ip"
    t.index ["user_type", "user_id"], name: "index_login_activities_on_user"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "amigo_details", "amigos"
  add_foreign_key "amigo_locations", "amigos"
  add_foreign_key "event_coordinators", "amigos"
  add_foreign_key "event_coordinators", "events"
  add_foreign_key "event_locations", "events"
  add_foreign_key "event_participants", "amigos"
  add_foreign_key "event_participants", "events"
  add_foreign_key "events", "amigo_locations", column: "event_location_id"
end
