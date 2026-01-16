module Teacher
  class SessionsController < BaseController
    before_action :set_session, only: [:show, :edit, :update, :destroy, :distribute, :progress]

    def index
      @sessions = Session.includes(:school, :assessment_version).order(created_at: :desc)
      @sessions = @sessions.where(status: params[:status]) if params[:status].present?
    end

    def show
      @submissions = @session.submissions.includes(:student)
    end

    def new
      @session = Session.new
    end

    def create
      @session = Session.new(session_params)
      @session.created_by_teacher = current_user
      @session.status = "draft"
      @session.access_code = generate_access_code

      if @session.save
        redirect_to teacher_session_path(@session), notice: "평가 세션이 생성되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @session.update(session_params)
        redirect_to teacher_session_path(@session), notice: "평가 세션이 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @session.destroy
      redirect_to teacher_sessions_path, notice: "평가 세션이 삭제되었습니다."
    end

    def distribute
      @session.update!(status: "active")
      redirect_to teacher_session_path(@session), notice: "세션이 활성화되었습니다. 접속 코드: #{@session.access_code}"
    end

    def progress
      @submissions = @session.submissions.includes(:student)
      render json: {
        total: @submissions.count,
        in_progress: @submissions.where(status: "in_progress").count,
        submitted: @submissions.where(status: "submitted").count
      }
    end

    private

    def set_session
      @session = Session.find(params[:id])
    end

    def session_params
      params.require(:session).permit(:school_id, :class_id, :assessment_version_id, :start_at, :end_at)
    end

    def generate_access_code
      loop do
        code = SecureRandom.alphanumeric(6).upcase
        break code unless Session.exists?(access_code: code)
      end
    end
  end
end
