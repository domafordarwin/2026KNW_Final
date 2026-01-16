module Teacher
  class DashboardController < BaseController
    def index
      @stats = {
        active_sessions: Session.where(status: "active").count,
        pending_submissions: Submission.where(status: "submitted").count,
        pending_feedback: TeacherFeedback.where(status: "draft").count,
        reports: Report.where(scope: "student").count
      }
      @recent_submissions = Submission.where(status: "submitted").order(submitted_at: :desc).limit(5)
    end
  end
end
