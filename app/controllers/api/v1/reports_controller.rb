module Api
  module V1
    class ReportsController < BaseController
      before_action -> { require_role!("admin", "teacher", "school_manager") }

      def show
        report = Report.find(params[:id])
        presenter = ReportPresenter.new(report)

        render json: {
          id: report.id,
          scope: report.scope,
          status: report.status,
          template_version: report.template_version,
          version: report.version,
          merged_feedback: presenter.merged_feedback,
          domain_scores: presenter.metrics_result&.domain_scores_json,
          subskill_scores: presenter.metrics_result&.subskill_scores_json,
          trait_type: presenter.trait_result&.trait_type
        }
      end
    end
  end
end
