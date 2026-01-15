module Api
  module V1
    class SubmissionsController < BaseController
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
