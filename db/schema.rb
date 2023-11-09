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

ActiveRecord::Schema[7.0].define(version: 2023_11_04_005453) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.string "apartment_number", limit: 32
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
    t.date "date_of_birth"
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
    t.boolean "member_in_good_standing"
    t.boolean "available_to_host"
    t.boolean "willing_to_donate"
    t.text "personal_bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_amigos_on_confirmation_token", unique: true
    t.index ["email"], name: "index_amigos_on_email", unique: true
    t.index ["reset_password_token"], name: "index_amigos_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_amigos_on_unlock_token", unique: true
    t.index ["user_name"], name: "index_amigos_on_user_name", unique: true
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti", unique: true
  end

  add_foreign_key "amigo_locations", "amigos"
end
