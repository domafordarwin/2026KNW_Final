class TeacherFeedback < ApplicationRecord
  self.table_name = "teacher_feedback"

  belongs_to :submission
  belongs_to :editor_teacher, class_name: "User"
  has_many :feedback_audits, dependent: :destroy
end
