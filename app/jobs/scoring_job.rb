class ScoringJob < ApplicationJob
  queue_as :default

  def perform(submission_id)
    submission = Submission.find(submission_id)
    ScoringService.new(submission).score_all
  end
end
