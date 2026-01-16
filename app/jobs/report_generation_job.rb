class ReportGenerationJob < ApplicationJob
  queue_as :default

  def perform(submission_id)
    submission = Submission.find(submission_id)

    # Ensure scoring is done
    ScoringService.new(submission).score_all unless submission.scoring_results.any?

    # Run feedback pipeline
    Ai::FeedbackPipeline.new(submission).run unless submission.ai_feedback_compiled

    # Create report record
    Report.find_or_create_by!(
      scope: "student",
      submission: submission
    ) do |report|
      report.version = "1.0"
      report.status = "generated"
      report.template_version = "v1"
    end
  end
end
