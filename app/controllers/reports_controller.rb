class ReportsController < ApplicationController
  def show
    @report = Report.find(params[:id])
    @presenter = ReportPresenter.new(@report)

    if @presenter.student_report?
      render :student
    else
      render :school
    end
  end
end
