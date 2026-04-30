ActiveRecord::Schema[8.1].define(version: 1) do
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
