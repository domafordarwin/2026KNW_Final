class Submission < ApplicationRecord
  belongs_to :session
  belongs_to :student, class_name: "User"

  has_many :responses, dependent: :destroy
  has_many :scoring_results, dependent: :destroy
  has_one :metrics_result, dependent: :destroy
  has_one :trait_result, dependent: :destroy
  has_many :ai_feedback_runs, dependent: :destroy
  has_one :ai_feedback_compiled, dependent: :destroy
  has_one :teacher_feedback, dependent: :destroy
  has_many :reports, dependent: :destroy
  has_one :book_candidate, dependent: :destroy
  has_one :book_guidance, dependent: :destroy
end
