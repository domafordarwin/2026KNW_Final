class CreateCoreTables < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :role, null: false
      t.string :status, null: false, default: "active"
      t.string :name, null: false
      t.string :email_optional
      t.timestamps
    end
    add_index :users, :email_optional, unique: true

    create_table :schools do |t|
      t.string :name, null: false
      t.timestamps
    end

    create_table :classes do |t|
      t.references :school, null: false, foreign_key: true
      t.string :grade, null: false
      t.string :name, null: false
      t.timestamps
    end

    create_table :student_profiles do |t|
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :school, null: false, foreign_key: true
      t.references :class, null: false, foreign_key: { to_table: :classes }
      t.string :student_code, null: false
      t.string :pii_ref_id
      t.timestamps
    end
    add_index :student_profiles, [:school_id, :student_code], unique: true

    create_table :parent_links do |t|
      t.references :parent_user, null: false, foreign_key: { to_table: :users }
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.string :access_token, null: false
      t.datetime :expires_at
      t.timestamps
    end
    add_index :parent_links, :access_token, unique: true

    create_table :passages do |t|
      t.string :title, null: false
      t.text :text, null: false
      t.string :grade_band
      t.json :tags_json
      t.timestamps
    end

    create_table :items do |t|
      t.references :passage, null: true, foreign_key: true
      t.string :item_type, null: false
      t.string :domain
      t.string :subskill
      t.string :difficulty
      t.text :prompt, null: false
      t.json :choices_json
      t.json :answer_key_json
      t.json :rubric_json
      t.integer :points, null: false, default: 1
      t.timestamps
    end

    create_table :assessment_versions do |t|
      t.string :name, null: false
      t.string :status, null: false
      t.datetime :published_at
      t.timestamps
    end

    create_table :assessment_version_items do |t|
      t.references :assessment_version, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.integer :order_no, null: false
      t.timestamps
    end
    add_index :assessment_version_items, [:assessment_version_id, :item_id], unique: true, name: "index_assessment_version_items_on_version_and_item"

    create_table :sessions do |t|
      t.references :school, null: false, foreign_key: true
      t.references :class, null: false, foreign_key: { to_table: :classes }
      t.references :assessment_version, null: false, foreign_key: true
      t.references :created_by_teacher, null: false, foreign_key: { to_table: :users }
      t.datetime :start_at
      t.datetime :end_at
      t.string :status, null: false
      t.string :access_code, null: false
      t.timestamps
    end
    add_index :sessions, :access_code, unique: true

    create_table :submissions do |t|
      t.references :session, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.datetime :started_at
      t.datetime :submitted_at
      t.string :status, null: false
      t.timestamps
    end
    add_index :submissions, [:session_id, :student_id]

    create_table :responses do |t|
      t.references :submission, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.json :answer_json
      t.integer :time_spent
      t.datetime :updated_at
      t.timestamps
    end
    add_index :responses, :submission_id

    create_table :scoring_results do |t|
      t.references :submission, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.integer :score, null: false, default: 0
      t.boolean :is_correct, null: false, default: false
      t.json :rubric_breakdown_json
      t.timestamps
    end
    add_index :scoring_results, :submission_id

    create_table :metrics_results do |t|
      t.references :submission, null: false, foreign_key: true
      t.json :domain_scores_json
      t.json :subskill_scores_json
      t.json :percentile_json
      t.datetime :computed_at
      t.timestamps
    end

    create_table :trait_results do |t|
      t.references :submission, null: false, foreign_key: true
      t.string :trait_type, null: false
      t.json :trait_scores_json
      t.datetime :computed_at
      t.timestamps
    end

    create_table :ai_feedback_runs do |t|
      t.references :submission, null: false, foreign_key: true
      t.string :step, null: false
      t.string :model, null: false
      t.string :prompt_version, null: false
      t.string :input_hash, null: false
      t.json :output_json
      t.string :status, null: false
      t.timestamps
    end
    add_index :ai_feedback_runs, [:submission_id, :step, :input_hash], name: "index_ai_feedback_runs_on_submission_step_hash"

    create_table :ai_feedback_compiled do |t|
      t.references :submission, null: false, foreign_key: true
      t.json :compiled_json
      t.timestamps
    end

    create_table :teacher_feedback do |t|
      t.references :submission, null: false, foreign_key: true
      t.references :editor_teacher, null: false, foreign_key: { to_table: :users }
      t.json :content_json
      t.json :diff_json
      t.string :status, null: false, default: "draft"
      t.datetime :approved_at
      t.timestamps
    end

    create_table :feedback_audit do |t|
      t.references :teacher_feedback, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.json :meta_json
      t.datetime :timestamp, null: false
      t.timestamps
    end

    create_table :reports do |t|
      t.string :scope, null: false
      t.references :submission, null: true, foreign_key: true
      t.references :session, null: true, foreign_key: true
      t.string :version, null: false
      t.string :status, null: false
      t.string :template_version, null: false
      t.string :storage_key
      t.timestamps
    end
    add_index :reports, [:scope, :submission_id]
    add_index :reports, [:scope, :session_id]

    create_table :report_access do |t|
      t.references :report, null: false, foreign_key: true
      t.references :subject_user, null: true, foreign_key: { to_table: :users }
      t.string :access_token
      t.boolean :can_view, null: false, default: true
      t.boolean :can_download, null: false, default: true
      t.datetime :expires_at
      t.timestamps
    end
    add_index :report_access, :access_token, unique: true

    create_table :book_catalog do |t|
      t.string :isbn
      t.string :title, null: false
      t.string :author
      t.string :grade_band
      t.string :difficulty
      t.json :tags_json
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :book_catalog, :active

    create_table :book_candidates do |t|
      t.references :submission, null: false, foreign_key: true
      t.json :candidate_book_ids_json
      t.datetime :generated_at
      t.timestamps
    end

    create_table :book_guidance do |t|
      t.references :submission, null: false, foreign_key: true
      t.json :selected_book_ids_json
      t.json :guidance_json
      t.timestamps
    end

    create_table :analytics_domain_agg do |t|
      t.references :session, null: false, foreign_key: true
      t.references :class, null: true, foreign_key: { to_table: :classes }
      t.string :domain, null: false
      t.float :avg
      t.float :std
      t.json :dist_json
      t.timestamps
    end

    create_table :analytics_subskill_agg do |t|
      t.references :session, null: false, foreign_key: true
      t.string :subskill, null: false
      t.float :avg
      t.json :dist_json
      t.timestamps
    end

    create_table :analytics_trait_agg do |t|
      t.references :session, null: false, foreign_key: true
      t.string :trait_type, null: false
      t.float :ratio
      t.timestamps
    end
  end
end
