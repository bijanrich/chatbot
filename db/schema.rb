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

ActiveRecord::Schema[7.1].define(version: 2025_03_26_030231) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "vector"

  create_table "chat_settings", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.boolean "show_thinking", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "model", default: "mistral-small"
    t.string "ollama_ip"
    t.text "prompt"
    t.text "persona"
    t.text "relationship_state"
    t.bigint "persona_id"
    t.jsonb "relationship_data"
    t.index ["chat_id"], name: "index_chat_settings_on_chat_id"
    t.index ["persona_id"], name: "index_chat_settings_on_persona_id"
  end

  create_table "chats", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "telegram_id"
    t.boolean "active", default: true
    t.index ["telegram_id", "active"], name: "index_chats_on_telegram_id_and_active"
    t.index ["telegram_id"], name: "index_chats_on_telegram_id_where_active", unique: true, where: "(active = true)"
  end

# Could not dump table "conversation_summaries" because of following StandardError
#   Unknown type 'vector(384)' for column 'embedding'

  create_table "creator_profiles", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name"
    t.string "onlyfans_username"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["organization_id"], name: "index_creator_profiles_on_organization_id"
    t.index ["user_id"], name: "index_creator_profiles_on_user_id"
  end

# Could not dump table "memory_facts" because of following StandardError
#   Unknown type 'vector(384)' for column 'embedding'

  create_table "messages", force: :cascade do |t|
    t.text "content"
    t.string "role"
    t.bigint "chat_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "telegram_chat_id"
    t.boolean "responded", default: false
    t.datetime "processed_at"
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["responded"], name: "index_messages_on_responded"
    t.index ["telegram_chat_id"], name: "index_messages_on_telegram_chat_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.string "billing_email"
    t.string "stripe_customer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payments", force: :cascade do |t|
    t.decimal "amount"
    t.string "status"
    t.string "stripe_payment_id"
    t.string "payment_method"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "personas", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.text "default_prompt", null: false
    t.jsonb "personality_traits", default: [], null: false
    t.string "tone", default: "neutral"
    t.string "emoji_usage", default: "light"
    t.jsonb "emotional_profile", default: {}, null: false
    t.jsonb "speech_style", default: {}, null: false
    t.jsonb "memory_behavior", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_personas_on_name", unique: true
  end

  create_table "plans", force: :cascade do |t|
    t.string "name"
    t.string "stripe_price_id"
    t.decimal "amount"
    t.string "interval"
    t.text "description"
    t.text "features"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "psychological_analyses", force: :cascade do |t|
    t.text "analysis"
    t.datetime "analyzed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "chat_id", null: false
    t.index ["chat_id"], name: "index_psychological_analyses_on_chat_id"
  end

  create_table "relationship_states", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.string "stage"
    t.string "emotional_state"
    t.float "trust_level"
    t.datetime "last_interaction"
    t.jsonb "flags"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_relationship_states_on_chat_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.string "data_type", default: "string"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "status"
    t.string "plan_name"
    t.string "stripe_subscription_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_subscriptions_on_organization_id"
  end

  create_table "telegram_messages", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.text "text", null: false
    t.text "response"
    t.boolean "responded", default: false, null: false
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_telegram_messages_on_chat_id"
    t.index ["responded"], name: "index_telegram_messages_on_responded"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
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
    t.string "username"
    t.string "account_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.string "name"
    t.string "role"
    t.bigint "organization_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "chat_settings", "chats"
  add_foreign_key "chat_settings", "personas"
  add_foreign_key "conversation_summaries", "chats"
  add_foreign_key "creator_profiles", "organizations"
  add_foreign_key "creator_profiles", "users"
  add_foreign_key "memory_facts", "chats"
  add_foreign_key "memory_facts", "messages"
  add_foreign_key "messages", "chats"
  add_foreign_key "payments", "users"
  add_foreign_key "psychological_analyses", "chats"
  add_foreign_key "relationship_states", "chats"
  add_foreign_key "subscriptions", "organizations"
  add_foreign_key "users", "organizations"
end
