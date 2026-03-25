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

ActiveRecord::Schema[8.0].define(version: 2026_03_25_075233) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
    t.index ["catastrophe_id"], name: "index_games_on_catastrophe_id"
  end

  create_table "player_cards", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.bigint "card_id", null: false
    t.boolean "revealed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "severity"
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
    t.index ["game_id"], name: "index_players_on_game_id"
  end

  add_foreign_key "games", "catastrophes"
  add_foreign_key "player_cards", "cards"
  add_foreign_key "player_cards", "players"
  add_foreign_key "players", "games"
end
