module Ai
  # LLM 응답 캐시 서비스
  # 동일한 입력에 대해 캐시된 응답을 반환하여 API 비용 절감
  class ResponseCache
    # 캐시 TTL (기본 7일)
    DEFAULT_TTL = 7.days

    def initialize(ttl: DEFAULT_TTL)
      @ttl = ttl
    end

    # 캐시에서 응답 조회
    # @param submission_id [Integer] 제출물 ID
    # @param step [String] 파이프라인 단계
    # @param input_hash [String] 입력 해시값
    # @return [Hash, nil] 캐시된 응답 또는 nil
    def get(submission_id, step, input_hash)
      cached = AiFeedbackRun.find_by(
        submission_id: submission_id,
        step: step,
        input_hash: input_hash,
        status: "success"
      )

      return nil unless cached
      return nil if cache_expired?(cached)

      cached.output_json
    end

    # 응답을 캐시에 저장
    # @param submission_id [Integer] 제출물 ID
    # @param step [String] 파이프라인 단계
    # @param input_hash [String] 입력 해시값
    # @param output [Hash] 저장할 응답
    # @param model [String] 사용된 모델명
    # @param prompt_version [String] 프롬프트 버전
    def set(submission_id, step, input_hash, output, model:, prompt_version:)
      AiFeedbackRun.find_or_initialize_by(
        submission_id: submission_id,
        step: step,
        input_hash: input_hash
      ).update!(
        output_json: output,
        status: "success",
        model: model,
        prompt_version: prompt_version
      )
    end

    # 실패 기록
    # @param submission_id [Integer] 제출물 ID
    # @param step [String] 파이프라인 단계
    # @param input_hash [String] 입력 해시값
    # @param error [String] 에러 메시지
    # @param model [String] 사용된 모델명
    # @param prompt_version [String] 프롬프트 버전
    def record_failure(submission_id, step, input_hash, error, model:, prompt_version:)
      AiFeedbackRun.create!(
        submission_id: submission_id,
        step: step,
        input_hash: input_hash,
        output_json: { error: error },
        status: "failed",
        model: model,
        prompt_version: prompt_version
      )
    end

    # 특정 제출물의 모든 캐시 무효화
    # @param submission_id [Integer] 제출물 ID
    def invalidate(submission_id)
      AiFeedbackRun.where(submission_id: submission_id).update_all(status: "invalidated")
    end

    # 특정 단계의 캐시만 무효화
    # @param submission_id [Integer] 제출물 ID
    # @param step [String] 파이프라인 단계
    def invalidate_step(submission_id, step)
      AiFeedbackRun.where(submission_id: submission_id, step: step).update_all(status: "invalidated")
    end

    # 캐시 통계 조회
    # @return [Hash] 캐시 통계
    def stats
      total = AiFeedbackRun.count
      hits = AiFeedbackRun.where(status: "success").count
      failures = AiFeedbackRun.where(status: "failed").count

      {
        total_entries: total,
        success_count: hits,
        failure_count: failures,
        hit_rate: total > 0 ? (hits.to_f / total * 100).round(2) : 0
      }
    end

    # 입력 데이터로부터 해시값 생성
    # @param input [Hash, String] 입력 데이터
    # @return [String] SHA256 해시값
    def self.compute_hash(input)
      data = input.is_a?(Hash) ? input.to_json : input.to_s
      Digest::SHA256.hexdigest(data)
    end

    private

    def cache_expired?(cached)
      return false if @ttl.nil?
      cached.created_at < @ttl.ago
    end
  end
end
