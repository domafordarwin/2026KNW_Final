module Parent
  class ReportsController < BaseController
    def index
      submission_ids = Submission.where(student_id: linked_student_ids).pluck(:id)
      @reports = Report.where(scope: "student", submission_id: submission_ids).includes(submission: :student)
    end

    def show
      @report = Report.find(params[:id])
      unless linked_student_ids.include?(@report.submission&.student_id)
        raise RoleAuthorization::AccessDenied
      end
      redirect_to report_path(@report)
    end
  end
end
