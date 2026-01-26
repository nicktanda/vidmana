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

ActiveRecord::Schema[8.0].define(version: 2026_01_26_013233) do
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

  create_table "beats", force: :cascade do |t|
    t.string "title", null: false
    t.text "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "order_index"
    t.integer "scene_id"
    t.integer "universe_id"
    t.index ["scene_id"], name: "index_beats_on_scene_id"
    t.index ["universe_id"], name: "index_beats_on_universe_id"
  end

  create_table "chapters", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "universe_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["universe_id"], name: "index_chapters_on_universe_id"
  end

  create_table "characters", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role"
    t.integer "universe_id"
    t.index ["universe_id"], name: "index_characters_on_universe_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "location_type"
    t.integer "universe_id"
    t.index ["universe_id"], name: "index_locations_on_universe_id"
  end

  create_table "mana_prompts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", default: "Default Prompt", null: false
    t.string "model", default: "x-ai/grok-4-fast", null: false
    t.index ["user_id"], name: "index_mana_prompts_on_user_id"
  end

  create_table "scenes", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "chapter_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chapter_id"], name: "index_scenes_on_chapter_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "stories", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "prompt"
    t.index ["user_id"], name: "index_stories_on_user_id"
  end

  create_table "universe_shares", force: :cascade do |t|
    t.integer "universe_id", null: false
    t.integer "user_id", null: false
    t.string "permission_level", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["universe_id", "user_id"], name: "index_universe_shares_on_universe_id_and_user_id", unique: true
    t.index ["universe_id"], name: "index_universe_shares_on_universe_id"
    t.index ["user_id"], name: "index_universe_shares_on_user_id"
  end

  create_table "universes", force: :cascade do |t|
    t.string "name", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "prompt"
    t.integer "mana_prompt_id"
    t.index ["mana_prompt_id"], name: "index_universes_on_mana_prompt_id"
    t.index ["user_id"], name: "index_universes_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.string "avatar_url"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "beats", "scenes"
  add_foreign_key "beats", "universes"
  add_foreign_key "chapters", "universes"
  add_foreign_key "characters", "universes"
  add_foreign_key "locations", "universes"
  add_foreign_key "mana_prompts", "users"
  add_foreign_key "scenes", "chapters"
  add_foreign_key "stories", "users"
  add_foreign_key "universe_shares", "universes"
  add_foreign_key "universe_shares", "users"
  add_foreign_key "universes", "mana_prompts"
  add_foreign_key "universes", "users"
end
