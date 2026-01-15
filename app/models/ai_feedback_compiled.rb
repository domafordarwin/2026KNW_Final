class AiFeedbackCompiled < ApplicationRecord
  self.table_name = "ai_feedback_compiled"

  belongs_to :submission
end
