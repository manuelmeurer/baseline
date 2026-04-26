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

ActiveRecord::Schema[8.0].define(version: 0) do
  create_table "baseline_errors_issues", force: :cascade do |t|
    t.string "fingerprint", null: false
    t.string "class_name", null: false
    t.text "message", null: false
    t.json "backtrace", default: [], null: false
    t.json "causes", default: [], null: false
    t.json "context", default: {}, null: false
    t.integer "occurrences_count", default: 0, null: false
    t.datetime "first_seen_at", null: false
    t.datetime "last_seen_at", null: false
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["class_name"], name: "index_baseline_errors_issues_on_class_name"
    t.index ["fingerprint"], name: "index_baseline_errors_issues_on_fingerprint", unique: true
    t.index ["last_seen_at"], name: "index_baseline_errors_issues_on_last_seen_at"
    t.index ["resolved_at"], name: "index_baseline_errors_issues_on_resolved_at"
  end
end
