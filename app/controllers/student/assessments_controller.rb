module Student
  class AssessmentsController < BaseController
    before_action :set_session, only: [:show, :take, :submit, :save_progress]
    before_action :set_submission, only: [:take, :submit, :save_progress]

    def index
      @active_sessions = Session.where(status: "active")
      @my_submissions = current_user.submissions.includes(session: :assessment_version)
    end

    def show
      @submission = current_user.submissions.find_by(session: @session)
    end

    def take
      @items = @session.assessment_version.items.includes(:passage)
      @responses = @submission.responses.index_by(&:item_id)
    end

    def save_progress
      save_responses
      @submission.update!(status: "in_progress")
      render json: { success: true, message: "임시 저장되었습니다." }
    end

    def submit
      save_responses
      @submission.update!(status: "submitted", submitted_at: Time.current)

      # Trigger scoring pipeline
      ScoringService.new(@submission).score_all

      redirect_to student_assessments_path, notice: "평가가 제출되었습니다."
    end

    private

    def set_session
      @session = Session.find(params[:id])
    end

    def set_submission
      @submission = current_user.submissions.find_or_create_by!(session: @session) do |s|
        s.status = "not_started"
        s.started_at = Time.current
      end
    end

    def save_responses
      return unless params[:responses].present?

      params[:responses].each do |item_id, answer|
        response = @submission.responses.find_or_initialize_by(item_id: item_id)
        response.answer_json = answer.is_a?(String) ? answer : answer.to_json
        response.save!
      end
    end
  end
end
