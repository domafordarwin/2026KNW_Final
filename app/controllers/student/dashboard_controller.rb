module Student
  class DashboardController < BaseController
    def index
      @active_sessions = Session.where(status: "active")
      @my_submissions = current_user.submissions.order(created_at: :desc).limit(5)
    end
  end
end
