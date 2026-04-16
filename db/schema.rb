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

ActiveRecord::Schema[8.0].define(version: 2026_04_16_121112) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_cards", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "card_type"
    t.string "code"
    t.boolean "requires_target"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bunker_features", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cards", force: :cascade do |t|
    t.string "category"
    t.string "name"
    t.string "tier"
    t.text "description"
    t.string "tags"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_curable", default: true
    t.integer "weight"
  end

  create_table "catastrophes", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "games", force: :cascade do |t|
    t.string "code"
    t.string "status"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "catastrophe_id", null: false
    t.integer "bunker_duration"
    t.string "bunker_supplies"
    t.string "bunker_size"
    t.integer "bunker_capacity"
    t.integer "current_round", default: 1
    t.string "bunker_items"
    t.string "threat"
    t.jsonb "bunker_features"
    t.bigint "threat_id"
    t.integer "active_raid_id"
    t.boolean "threat_revealed"
    t.boolean "raid_params_revealed"
    t.jsonb "raid_candidate_ids", default: []
    t.string "host_token", default: -> { "upper(substr(md5((random())::text), 1, 16))" }, null: false
    t.index ["catastrophe_id"], name: "index_games_on_catastrophe_id"
    t.index ["host_token"], name: "index_games_on_host_token", unique: true
    t.index ["threat_id"], name: "index_games_on_threat_id"
  end

  create_table "player_action_cards", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.bigint "action_card_id", null: false
    t.boolean "used", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_card_id"], name: "index_player_action_cards_on_action_card_id"
    t.index ["player_id"], name: "index_player_action_cards_on_player_id"
  end

  create_table "player_cards", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.bigint "card_id", null: false
    t.boolean "revealed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "severity"
    t.boolean "bonus", default: false, null: false
    t.index ["card_id"], name: "index_player_cards_on_card_id"
    t.index ["player_id"], name: "index_player_cards_on_player_id"
  end

  create_table "players", force: :cascade do |t|
    t.bigint "game_id", null: false
    t.string "name"
    t.string "gender"
    t.integer "age"
    t.boolean "survived", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_infertile"
    t.integer "profession_experience"
    t.integer "hobby_experience"
    t.boolean "biology_revealed", default: false
    t.boolean "eliminated", default: false
    t.string "raid_status", default: "at_home"
    t.text "raid_outcome"
    t.string "nickname"
    t.index ["game_id"], name: "index_players_on_game_id"
  end

  create_table "raids", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "required_tags"
    t.string "dangerous_tags"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.binary "payload", null: false
    t.datetime "created_at", null: false
    t.bigint "channel_hash", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "threats", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "games", "catastrophes"
  add_foreign_key "games", "threats"
  add_foreign_key "player_action_cards", "action_cards"
  add_foreign_key "player_action_cards", "players"
  add_foreign_key "player_cards", "cards"
  add_foreign_key "player_cards", "players"
  add_foreign_key "players", "games"
end
