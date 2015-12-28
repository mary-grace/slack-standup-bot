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

ActiveRecord::Schema.define(version: 20151017005039) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "channels", force: :cascade do |t|
    t.string "name"
    t.string "slack_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "channel_type", default: "group"
    t.string "name",         default: "Standup"
    t.string "bot_id"
    t.string "bot_name"
    t.string "web_url"
  end

  create_table "standups", force: :cascade do |t|
    t.text     "yesterday"
    t.text     "today"
    t.text     "conflicts"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "channel_id"
    t.integer  "user_id"
    t.integer  "order",      default: 1
    t.string   "state"
  end

  create_table "users", force: :cascade do |t|
    t.string  "slack_id"
    t.string  "full_name"
    t.boolean "admin",      default: false
    t.string  "nickname"
    t.integer "channel_id"
    t.string  "avatar_url"
    t.boolean "bot",        default: false
  end

end
