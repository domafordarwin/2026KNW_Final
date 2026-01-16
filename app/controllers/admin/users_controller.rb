module Admin
  class UsersController < BaseController
    before_action :set_user, only: [:show, :edit, :update, :destroy]

    def index
      @users = User.order(created_at: :desc)
      @users = @users.where(role: params[:role]) if params[:role].present?
      @users = @users.where(status: params[:status]) if params[:status].present?
      @users = @users.where("name LIKE ? OR email_optional LIKE ?", "%#{params[:q]}%", "%#{params[:q]}%") if params[:q].present?
    end

    def show
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to admin_users_path, notice: "사용자가 생성되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      update_params = user_params
      update_params = update_params.except(:password, :password_confirmation) if update_params[:password].blank?

      if @user.update(update_params)
        redirect_to admin_users_path, notice: "사용자 정보가 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user == current_user
        redirect_to admin_users_path, alert: "본인 계정은 삭제할 수 없습니다."
        return
      end

      @user.destroy
      redirect_to admin_users_path, notice: "사용자가 삭제되었습니다."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(
        :name, :email_optional, :role, :status, :password, :password_confirmation
      )
    end
  end
end
