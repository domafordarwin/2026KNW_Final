module Teacher
  class SubmissionsController < BaseController
    def index
      @submissions = Submission.includes(:student, :session).order(created_at: :desc)
      @submissions = @submissions.where(status: params[:status]) if params[:status].present?
    end

    def show
      @submission = Submission.find(params[:id])
      @responses = @submission.responses.includes(:item)
      @scoring_results = @submission.scoring_results.index_by(&:item_id)
    end
  end
end
