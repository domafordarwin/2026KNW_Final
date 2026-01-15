class FeedbackAudit < ApplicationRecord
  self.table_name = "feedback_audit"

  belongs_to :teacher_feedback
  belongs_to :actor, class_name: "User"
end
