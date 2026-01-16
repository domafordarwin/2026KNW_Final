module Student
  class ReportsController < BaseController
    def index
      submission_ids = current_user.submissions.pluck(:id)
      @reports = Report.where(scope: "student", submission_id: submission_ids)
    end

    def show
      @report = Report.find(params[:id])
      unless @report.submission&.student_id == current_user.id
        raise RoleAuthorization::AccessDenied
      end
      redirect_to report_path(@report)
    end
  end
end
