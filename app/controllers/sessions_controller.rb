class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  def new
    redirect_to root_path if current_user
  end

  def create
    user = User.find_by(email_optional: params[:email])

    if user && authenticate_user(user, params[:password])
      session[:user_id] = user.id
      redirect_to after_login_path(user), notice: "로그인되었습니다."
    else
      flash.now[:alert] = "이메일 또는 비밀번호가 올바르지 않습니다."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: "로그아웃되었습니다."
  end

  private

  def authenticate_user(user, password)
    return false unless user.respond_to?(:password_digest) && user.password_digest.present?

    BCrypt::Password.new(user.password_digest) == password
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def after_login_path(user)
    case user.role
    when "admin"
      admin_root_path
    when "school_manager"
      school_manager_root_path
    when "teacher"
      teacher_root_path
    when "student"
      student_root_path
    when "parent"
      parent_root_path
    else
      root_path
    end
  end
end
