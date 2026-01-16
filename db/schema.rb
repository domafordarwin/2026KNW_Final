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

ActiveRecord::Schema[8.1].define(version: 2026_01_16_030000) do
  create_table "ai_feedback_compiled", force: :cascade do |t|
    t.json "compiled_json"
    t.datetime "created_at", null: false
    t.integer "submission_id", null: false
    t.datetime "updated_at", null: false
    t.index ["submission_id"], name: "index_ai_feedback_compiled_on_submission_id"
  end

  create_table "ai_feedback_runs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "input_hash", null: false
    t.string "model", null: false
    t.json "output_json"
    t.string "prompt_version", null: false
    t.string "status", null: false
    t.string "step", null: false
    t.integer "submission_id", null: false
    t.datetime "updated_at", null: false
    t.index ["submission_id", "step", "input_hash"], name: "index_ai_feedback_runs_on_submission_step_hash"
    t.index ["submission_id"], name: "index_ai_feedback_runs_on_submission_id"
  end

  create_table "analytics_domain_agg", force: :cascade do |t|
    t.float "avg"
    t.integer "class_id"
    t.datetime "created_at", null: false
    t.json "dist_json"
    t.string "domain", null: false
    t.integer "session_id", null: false
    t.float "std"
    t.datetime "updated_at", null: false
    t.index ["class_id"], name: "index_analytics_domain_agg_on_class_id"
    t.index ["session_id"], name: "index_analytics_domain_agg_on_session_id"
  end

  create_table "analytics_subskill_agg", force: :cascade do |t|
    t.float "avg"
    t.datetime "created_at", null: false
    t.json "dist_json"
    t.integer "session_id", null: false
    t.string "subskill", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_analytics_subskill_agg_on_session_id"
  end

  create_table "analytics_trait_agg", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "ratio"
    t.integer "session_id", null: false
    t.string "trait_type", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_analytics_trait_agg_on_session_id"
  end

  create_table "assessment_version_items", force: :cascade do |t|
    t.integer "assessment_version_id", null: false
    t.datetime "created_at", null: false
    t.integer "item_id", null: false
    t.integer "order_no", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_version_id", "item_id"], name: "index_assessment_version_items_on_version_and_item", unique: true
    t.index ["assessment_version_id"], name: "index_assessment_version_items_on_assessment_version_id"
    t.index ["item_id"], name: "index_assessment_version_items_on_item_id"
  end

  create_table "assessment_versions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "published_at"
    t.string "status", null: false
    t.datetime "updated_at", null: false
  end

  create_table "book_candidates", force: :cascade do |t|
    t.json "candidate_book_ids_json"
    t.datetime "created_at", null: false
    t.datetime "generated_at"
    t.integer "submission_id", null: false
    t.datetime "updated_at", null: false
    t.index ["submission_id"], name: "index_book_candidates_on_submission_id"
  end

  create_table "book_catalog", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "author"
    t.datetime "created_at", null: false
    t.string "difficulty"
    t.string "grade_band"
    t.string "isbn"
    t.json "tags_json"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_book_catalog_on_active"
  end

  create_table "book_guidance", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "guidance_json"
    t.json "selected_book_ids_json"
    t.integer "submission_id", null: false
    t.datetime "updated_at", null: false
    t.index ["submission_id"], name: "index_book_guidance_on_submission_id"
  end

  create_table "classes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "grade", null: false
    t.string "name", null: false
    t.integer "school_id", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "index_classes_on_school_id"
  end

  create_table "feedback_audit", force: :cascade do |t|
    t.string "action", null: false
    t.integer "actor_id", null: false
    t.datetime "created_at", null: false
    t.json "meta_json"
    t.integer "teacher_feedback_id", null: false
    t.datetime "timestamp", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_feedback_audit_on_actor_id"
    t.index ["teacher_feedback_id"], name: "index_feedback_audit_on_teacher_feedback_id"
  end

  create_table "items", force: :cascade do |t|
    t.json "answer_key_json"
    t.json "choices_json"
    t.datetime "created_at", null: false
    t.string "difficulty"
    t.string "domain"
    t.string "item_type", null: false
    t.integer "passage_id"
    t.integer "points", default: 1, null: false
    t.text "prompt", null: false
    t.json "rubric_json"
    t.string "subskill"
    t.datetime "updated_at", null: false
    t.index ["passage_id"], name: "index_items_on_passage_id"
  end

  create_table "metrics_results", force: :cascade do |t|
    t.datetime "computed_at"
    t.datetime "created_at", null: false
    t.json "domain_scores_json"
    t.json "percentile_json"
    t.integer "submission_id", null: false
    t.json "subskill_scores_json"
    t.datetime "updated_at", null: false
    t.index ["submission_id"], name: "index_metrics_results_on_submission_id"
  end

  create_table "parent_links", force: :cascade do |t|
    t.string "access_token", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.integer "parent_user_id", null: false
    t.integer "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["access_token"], name: "index_parent_links_on_access_token", unique: true
    t.index ["parent_user_id"], name: "index_parent_links_on_parent_user_id"
    t.index ["student_id"], name: "index_parent_links_on_student_id"
  end

  create_table "passages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "grade_band"
    t.json "tags_json"
    t.text "text", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end

  create_table "report_access", force: :cascade do |t|
    t.string "access_token"
    t.boolean "can_download", default: true, null: false
    t.boolean "can_view", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.integer "report_id", null: false
    t.integer "subject_user_id"
    t.datetime "updated_at", null: false
    t.index ["access_token"], name: "index_report_access_on_access_token", unique: true
    t.index ["report_id"], name: "index_report_access_on_report_id"
    t.index ["subject_user_id"], name: "index_report_access_on_subject_user_id"
  end

  create_table "reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "scope", null: false
    t.integer "session_id"
    t.string "status", null: false
    t.string "storage_key"
    t.integer "submission_id"
    t.string "template_version", null: false
    t.datetime "updated_at", null: false
    t.string "version", null: false
    t.index ["scope", "session_id"], name: "index_reports_on_scope_and_session_id"
    t.index ["scope", "submission_id"], name: "index_reports_on_scope_and_submission_id"
    t.index ["session_id"], name: "index_reports_on_session_id"
    t.index ["submission_id"], name: "index_reports_on_submission_id"
  end

  create_table "responses", force: :cascade do |t|
    t.json "answer_json"
    t.datetime "created_at", null: false
    t.integer "item_id", null: false
    t.integer "submission_id", null: false
    t.integer "time_spent"
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_responses_on_item_id"
    t.index ["submission_id"], name: "index_responses_on_submission_id"
  end

  create_table "schools", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "scoring_results", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_correct", default: false, null: false
    t.integer "item_id", null: false
    t.json "rubric_breakdown_json"
    t.integer "score", default: 0, null: false
    t.integer "submission_id", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_scoring_results_on_item_id"
    t.index ["submission_id"], name: "index_scoring_results_on_submission_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "access_code", null: false
    t.integer "assessment_version_id", null: false
    t.integer "class_id", null: false
    t.datetime "created_at", null: false
    t.integer "created_by_teacher_id", null: false
    t.datetime "end_at"
    t.integer "school_id", null: false
    t.datetime "start_at"
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["access_code"], name: "index_sessions_on_access_code", unique: true
    t.index ["assessment_version_id"], name: "index_sessions_on_assessment_version_id"
    t.index ["class_id"], name: "index_sessions_on_class_id"
    t.index ["created_by_teacher_id"], name: "index_sessions_on_created_by_teacher_id"
    t.index ["school_id"], name: "index_sessions_on_school_id"
  end

  create_table "student_profiles", force: :cascade do |t|
    t.integer "class_id", null: false
    t.datetime "created_at", null: false
    t.string "pii_ref_id"
    t.integer "school_id", null: false
    t.string "student_code", null: false
    t.integer "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["class_id"], name: "index_student_profiles_on_class_id"
    t.index ["school_id", "student_code"], name: "index_student_profiles_on_school_id_and_student_code", unique: true
    t.index ["school_id"], name: "index_student_profiles_on_school_id"
    t.index ["student_id"], name: "index_student_profiles_on_student_id"
  end

  create_table "submissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "session_id", null: false
    t.datetime "started_at"
    t.string "status", null: false
    t.integer "student_id", null: false
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.index ["session_id", "student_id"], name: "index_submissions_on_session_id_and_student_id"
    t.index ["session_id"], name: "index_submissions_on_session_id"
    t.index ["student_id"], name: "index_submissions_on_student_id"
  end

  create_table "teacher_feedback", force: :cascade do |t|
    t.datetime "approved_at"
    t.json "content_json"
    t.datetime "created_at", null: false
    t.json "diff_json"
    t.integer "editor_teacher_id", null: false
    t.string "status", default: "draft", null: false
    t.integer "submission_id", null: false
    t.datetime "updated_at", null: false
    t.index ["editor_teacher_id"], name: "index_teacher_feedback_on_editor_teacher_id"
    t.index ["submission_id"], name: "index_teacher_feedback_on_submission_id"
  end

  create_table "trait_results", force: :cascade do |t|
    t.datetime "computed_at"
    t.datetime "created_at", null: false
    t.integer "submission_id", null: false
    t.json "trait_scores_json"
    t.string "trait_type", null: false
    t.datetime "updated_at", null: false
    t.index ["submission_id"], name: "index_trait_results_on_submission_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_optional"
    t.string "name", null: false
    t.string "password_digest"
    t.string "role", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["email_optional"], name: "index_users_on_email_optional", unique: true
  end

  add_foreign_key "ai_feedback_compiled", "submissions"
  add_foreign_key "ai_feedback_runs", "submissions"
  add_foreign_key "analytics_domain_agg", "classes"
  add_foreign_key "analytics_domain_agg", "sessions"
  add_foreign_key "analytics_subskill_agg", "sessions"
  add_foreign_key "analytics_trait_agg", "sessions"
  add_foreign_key "assessment_version_items", "assessment_versions"
  add_foreign_key "assessment_version_items", "items"
  add_foreign_key "book_candidates", "submissions"
  add_foreign_key "book_guidance", "submissions"
  add_foreign_key "classes", "schools"
  add_foreign_key "feedback_audit", "teacher_feedbacks"
  add_foreign_key "feedback_audit", "users", column: "actor_id"
  add_foreign_key "items", "passages"
  add_foreign_key "metrics_results", "submissions"
  add_foreign_key "parent_links", "users", column: "parent_user_id"
  add_foreign_key "parent_links", "users", column: "student_id"
  add_foreign_key "report_access", "reports"
  add_foreign_key "report_access", "users", column: "subject_user_id"
  add_foreign_key "reports", "sessions"
  add_foreign_key "reports", "submissions"
  add_foreign_key "responses", "items"
  add_foreign_key "responses", "submissions"
  add_foreign_key "scoring_results", "items"
  add_foreign_key "scoring_results", "submissions"
  add_foreign_key "sessions", "assessment_versions"
  add_foreign_key "sessions", "classes"
  add_foreign_key "sessions", "schools"
  add_foreign_key "sessions", "users", column: "created_by_teacher_id"
  add_foreign_key "student_profiles", "classes"
  add_foreign_key "student_profiles", "schools"
  add_foreign_key "student_profiles", "users", column: "student_id"
  add_foreign_key "submissions", "sessions"
  add_foreign_key "submissions", "users", column: "student_id"
  add_foreign_key "teacher_feedback", "submissions"
  add_foreign_key "teacher_feedback", "users", column: "editor_teacher_id"
  add_foreign_key "trait_results", "submissions"
end
