module SchoolManager
  class ReportsController < BaseController
    def index
      @reports = Report.where(scope: "school").order(created_at: :desc)
    end

    def show
      @report = Report.find(params[:id])
    end
  end
end
