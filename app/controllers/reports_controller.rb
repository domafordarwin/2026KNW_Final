class ReportsController < ApplicationController
  layout "report"
  before_action :set_report
  before_action :authorize_report_access!
  before_action :set_audience

  def show
    @presenter = ReportPresenter.new(@report)

    if @presenter.student_report?
      render :student
    else
      render :school
    end
  end

  private

  def set_report
    @report = Report.find(params[:id])
  end

  def authorize_report_access!
    return if token_access?
    return if user_access?
    return if staff_access?

    raise RoleAuthorization::AccessDenied
  end

  def token_access?
    token = params[:token]
    return false if token.blank?
    return false unless @report.scope == "student"

    ReportAccess.where(report: @report, access_token: token)
      .where("expires_at IS NULL OR expires_at >= ?", Time.current)
      .exists?
  end

  def user_access?
    return false unless current_user

    ReportAccess.exists?(report: @report, subject_user: current_user)
  end

  def staff_access?
    return false unless current_user

    %w[admin teacher school_manager].include?(current_user.role)
  end

  def set_audience
    @audience =
      if staff_access?
        "teacher"
      elsif current_user&.role == "parent" || token_access?
        "parent"
      elsif current_user&.role == "student"
        "student"
      else
        "student"
      end
  end
end
