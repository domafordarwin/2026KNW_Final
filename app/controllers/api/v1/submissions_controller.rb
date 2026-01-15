module Api
  module V1
    class SubmissionsController < BaseController
      before_action -> { require_role!("admin", "teacher", "school_manager") }

      def show
        submission = Submission.find(params[:id])
        render json: submission.as_json(
          include: {
            responses: {},
            scoring_results: {},
            metrics_result: {},
            trait_result: {}
          }
        )
      end
    end
  end
end
