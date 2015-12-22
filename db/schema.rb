# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151028154142) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "invitation_events", force: :cascade do |t|
    t.integer  "invitation_id"
    t.string   "status"
    t.string   "description"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "invitation_events", ["invitation_id"], name: "index_invitation_events_on_invitation_id", using: :btree

  create_table "invitations", force: :cascade do |t|
    t.string   "status"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "provider_id"
    t.integer  "job_id"
    t.text     "description"
  end

  add_index "invitations", ["job_id"], name: "index_invitations_on_job_id", using: :btree

  create_table "job_events", force: :cascade do |t|
    t.integer  "job_id"
    t.string   "description"
    t.string   "status"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "job_events", ["job_id"], name: "index_job_events_on_job_id", using: :btree

  create_table "jobs", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.string   "owner_id"
    t.date     "due_date"
    t.string   "status"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.json     "metadata",        default: {},    null: false
    t.boolean  "invitation_only", default: false
    t.date     "start_date"
    t.date     "finish_date"
    t.date     "closed_date"
  end

  create_table "offer_events", force: :cascade do |t|
    t.integer  "offer_id"
    t.string   "description"
    t.string   "provider_id"
    t.string   "status"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "offer_events", ["offer_id"], name: "index_offer_events_on_offer_id", using: :btree

  create_table "offer_invitations", force: :cascade do |t|
    t.integer "invitation_id"
    t.integer "offer_id"
  end

  add_index "offer_invitations", ["invitation_id"], name: "index_offer_invitations_on_invitation_id", using: :btree
  add_index "offer_invitations", ["offer_id"], name: "index_offer_invitations_on_offer_id", using: :btree

  create_table "offer_records", force: :cascade do |t|
    t.integer  "offer_id"
    t.string   "record_type"
    t.string   "reason"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.json     "metadata",    default: {}, null: false
  end

  add_index "offer_records", ["offer_id"], name: "index_offer_records_on_offer_id", using: :btree

  create_table "offers", force: :cascade do |t|
    t.integer  "job_id"
    t.string   "description"
    t.string   "provider_id"
    t.string   "status"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.json     "metadata",    default: {}, null: false
  end

  add_index "offers", ["job_id"], name: "index_offers_on_job_id", using: :btree

  add_foreign_key "invitation_events", "invitations"
  add_foreign_key "invitations", "jobs"
  add_foreign_key "job_events", "jobs"
  add_foreign_key "offer_events", "offers"
  add_foreign_key "offer_invitations", "invitations"
  add_foreign_key "offer_invitations", "offers"
  add_foreign_key "offer_records", "offers"
  add_foreign_key "offers", "jobs"
end
