class FeedbackPipelineJob < ApplicationJob
  queue_as :default

  # @param submission_id [Integer] 제출물 ID
  # @param section [String, nil] 재생성할 특정 섹션 (nil이면 전체 실행)
  def perform(submission_id, section: nil)
    submission = Submission.find(submission_id)
    pipeline = Ai::FeedbackPipeline.new(submission)

    if section.present?
      Rails.logger.info("[FeedbackPipelineJob] 섹션 재생성 시작: #{section}")
      pipeline.run(section: section)
    else
      Rails.logger.info("[FeedbackPipelineJob] 전체 파이프라인 시작")
      pipeline.run
    end

    Rails.logger.info("[FeedbackPipelineJob] 완료: submission_id=#{submission_id}")
  rescue StandardError => e
    Rails.logger.error("[FeedbackPipelineJob] 실패: #{e.message}")
    raise e
  end
end
