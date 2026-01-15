class ReportAccess < ApplicationRecord
  self.table_name = "report_access"

  belongs_to :report
  belongs_to :subject_user, class_name: "User", optional: true
end
