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

ActiveRecord::Schema[8.0].define(version: 2025_09_25_075153) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

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

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "tokens", default: {}, null: false
    t.string "position"
    t.integer "user_id", null: false
    t.json "alternate_emails", default: [], null: false
    t.index ["user_id"], name: "index_admin_users_on_user_id"
    t.check_constraint "JSON_TYPE(alternate_emails) = 'array'", name: "user_alternate_emails_is_array"
  end

  create_table "attendee_profiles", force: :cascade do |t|
    t.string "tagline"
    t.string "linkedin"
    t.string "website"
    t.text "bio"
    t.boolean "public", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.string "company"
    t.index ["user_id"], name: "index_attendee_profiles_on_user_id"
  end

  create_table "brevo_events", force: :cascade do |t|
    t.string "kind", null: false
    t.json "data", default: {}, null: false
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contact_requests", force: :cascade do |t|
    t.string "locale", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.string "company"
    t.string "phone"
    t.integer "kind", null: false
    t.json "details", default: {}, null: false
    t.text "message", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "email_deliveries", force: :cascade do |t|
    t.string "subject", null: false
    t.string "message_id"
    t.string "reply_to"
    t.text "html_content"
    t.text "text_content"
    t.json "recipients", default: {}, null: false
    t.json "cc_recipients", default: {}, null: false
    t.json "bcc_recipients", default: {}, null: false
    t.json "bounced_emails", default: [], null: false
    t.json "rejected_emails", default: [], null: false
    t.datetime "sent_at"
    t.datetime "scheduled_at"
    t.integer "admin_user_id"
    t.string "deliverable_type", null: false
    t.integer "deliverable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id"], name: "index_email_deliveries_on_admin_user_id"
    t.index ["deliverable_type", "deliverable_id"], name: "index_email_deliveries_on_deliverable"
    t.check_constraint "JSON_TYPE(bounced_emails) = 'array'", name: "email_delivery_bounced_emails_is_array"
    t.check_constraint "JSON_TYPE(rejected_emails) = 'array'", name: "email_delivery_rejected_emails_is_array"
  end

  create_table "events", force: :cascade do |t|
    t.string "name", null: false
    t.string "pretix_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "started_on"
    t.date "ended_on"
    t.string "subdomain"
    t.string "slug", null: false
    t.string "aftermovie_youtube_id"
    t.datetime "published_at"
    t.index ["name"], name: "index_events_on_name", unique: true
    t.index ["pretix_id"], name: "index_events_on_pretix_id", unique: true
    t.index ["slug"], name: "index_events_on_slug", unique: true
    t.index ["subdomain"], name: "index_events_on_subdomain", unique: true
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "message_groups", force: :cascade do |t|
    t.string "kind", null: false
    t.string "subject"
    t.datetime "sending_started_at"
    t.string "messageable_type", null: false
    t.integer "messageable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "locale", null: false
    t.index ["messageable_type", "messageable_id"], name: "index_message_groups_on_messageable"
  end

  create_table "messages", force: :cascade do |t|
    t.string "type", null: false
    t.integer "kind", null: false
    t.string "messageable_type"
    t.integer "messageable_id"
    t.string "recipient_type", null: false
    t.integer "recipient_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "message_group_id"
    t.index ["message_group_id"], name: "index_messages_on_message_group_id"
    t.index ["messageable_type", "messageable_id"], name: "index_messages_on_messageable"
    t.index ["recipient_type", "recipient_id"], name: "index_messages_on_recipient"
  end

  create_table "partner_companies", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "partners", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "partnerships", force: :cascade do |t|
    t.integer "partner_company_id", null: false
    t.integer "event_id", null: false
    t.integer "level", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_partnerships_on_event_id"
    t.index ["partner_company_id", "event_id"], name: "index_partnerships_on_partner_company_id_and_event_id", unique: true
    t.index ["partner_company_id"], name: "index_partnerships_on_partner_company_id"
  end

  create_table "reactions", force: :cascade do |t|
    t.string "url", null: false
    t.integer "event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_reactions_on_event_id"
  end

  create_table "sections", force: :cascade do |t|
    t.string "headline"
    t.string "slug", null: false
    t.integer "position", null: false
    t.string "sectionable_type", null: false
    t.integer "sectionable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sectionable_type", "sectionable_id"], name: "index_sections_on_sectionable"
    t.index ["slug"], name: "index_sections_on_slug", unique: true
  end

  create_table "spam_requests", force: :cascade do |t|
    t.string "kind", null: false
    t.json "data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "speaker_profiles", force: :cascade do |t|
    t.string "tagline_en"
    t.string "linkedin"
    t.string "website"
    t.text "bio_en"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "bio_de"
    t.string "tagline_de"
    t.integer "user_id", null: false
    t.string "company"
    t.index ["user_id"], name: "index_speaker_profiles_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string "identifier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier"], name: "index_subscriptions_on_identifier", unique: true
  end

  create_table "talk_favorites", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "talk_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["talk_id"], name: "index_talk_favorites_on_talk_id"
    t.index ["user_id", "talk_id"], name: "index_talk_favorites_on_user_id_and_talk_id", unique: true
    t.index ["user_id"], name: "index_talk_favorites_on_user_id"
  end

  create_table "talk_speakers", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "talk_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["talk_id"], name: "index_talk_speakers_on_talk_id"
    t.index ["user_id", "talk_id"], name: "index_talk_speakers_on_user_id_and_talk_id", unique: true
    t.index ["user_id"], name: "index_talk_speakers_on_user_id"
  end

  create_table "talks", force: :cascade do |t|
    t.string "title"
    t.string "locale"
    t.text "description"
    t.datetime "started_at"
    t.datetime "published_at"
    t.integer "minutes"
    t.virtual "ended_at", type: :datetime, as: "datetime(started_at, '+' || minutes || ' minutes')", stored: false
    t.integer "event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "tracks", default: [], null: false
    t.json "locations", default: [], null: false
    t.string "slug", null: false
    t.string "kind"
    t.json "audiences", default: [], null: false
    t.json "levels", default: [], null: false
    t.index ["event_id"], name: "index_talks_on_event_id"
    t.index ["slug"], name: "index_talks_on_slug", unique: true
  end

  create_table "tasks", force: :cascade do |t|
    t.string "title", null: false
    t.string "todoist_id"
    t.string "identifier"
    t.text "details"
    t.datetime "done_at"
    t.date "due_on", null: false
    t.integer "priority", null: false
    t.string "responsible_type", null: false
    t.integer "responsible_id", null: false
    t.string "creator_type"
    t.integer "creator_id"
    t.string "taskable_type"
    t.integer "taskable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_type", "creator_id"], name: "index_tasks_on_creator"
    t.index ["responsible_type", "responsible_id"], name: "index_tasks_on_responsible"
    t.index ["taskable_type", "taskable_id"], name: "index_tasks_on_taskable"
    t.index ["todoist_id"], name: "index_tasks_on_todoist_id", unique: true
  end

  create_table "testimonials", force: :cascade do |t|
    t.string "name", null: false
    t.string "title", null: false
    t.string "body", null: false
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ticket_transfer_requests", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.datetime "resolved_at"
    t.integer "ticket_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug", null: false
    t.integer "user_id", null: false
    t.index ["slug"], name: "index_ticket_transfer_requests_on_slug", unique: true
    t.index ["ticket_id"], name: "index_ticket_transfer_requests_on_ticket_id"
    t.index ["user_id"], name: "index_ticket_transfer_requests_on_user_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.string "identifier"
    t.json "data", default: {}, null: false
    t.integer "event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "admin_user_id"
    t.datetime "cancelled_at"
    t.integer "price_cents", default: 0, null: false
    t.string "price_currency", default: "EUR", null: false
    t.string "slug", null: false
    t.integer "user_id", null: false
    t.string "pretix_item_id"
    t.datetime "checked_in_at"
    t.index ["admin_user_id"], name: "index_tickets_on_admin_user_id"
    t.index ["event_id"], name: "index_tickets_on_event_id"
    t.index ["identifier"], name: "index_tickets_on_identifier", unique: true
    t.index ["slug"], name: "index_tickets_on_slug", unique: true
    t.index ["user_id"], name: "index_tickets_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug", null: false
    t.string "title"
    t.json "subscriptions", default: [], null: false
    t.string "locale", null: false
    t.string "remember_token"
    t.string "password_digest"
    t.integer "gender"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["slug"], name: "index_users_on_slug", unique: true
    t.check_constraint "JSON_TYPE(subscriptions) = 'array'", name: "user_subscriptions_is_array"
  end

  create_table "versions", force: :cascade do |t|
    t.string "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.json "object"
    t.json "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "admin_users", "users"
  add_foreign_key "attendee_profiles", "users"
  add_foreign_key "email_deliveries", "admin_users"
  add_foreign_key "messages", "message_groups"
  add_foreign_key "partnerships", "events"
  add_foreign_key "partnerships", "partner_companies"
  add_foreign_key "reactions", "events"
  add_foreign_key "speaker_profiles", "users"
  add_foreign_key "talk_favorites", "talks"
  add_foreign_key "talk_favorites", "users"
  add_foreign_key "talk_speakers", "talks"
  add_foreign_key "talk_speakers", "users"
  add_foreign_key "talks", "events"
  add_foreign_key "ticket_transfer_requests", "tickets"
  add_foreign_key "ticket_transfer_requests", "users"
  add_foreign_key "tickets", "admin_users"
  add_foreign_key "tickets", "events"
  add_foreign_key "tickets", "users"
end
