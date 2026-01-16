class DashboardController < ApplicationController
  def index
    if current_user
      redirect_to_role_dashboard
    else
      redirect_to login_path
    end
  end

  def home
    @user = current_user
  end

  private

  def redirect_to_role_dashboard
    case current_user.role
    when "admin"
      redirect_to admin_root_path
    when "school_manager"
      redirect_to school_manager_root_path
    when "teacher"
      redirect_to teacher_root_path
    when "student"
      redirect_to student_root_path
    when "parent"
      redirect_to parent_root_path
    else
      render :home
    end
  end
end
