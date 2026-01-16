module Scoring
  # 백분위 및 등급 계산 서비스
  # 학생의 점수를 동일 학년군/학급 내에서의 상대적 위치로 변환
  class PercentileCalculator
    GRADE_THRESHOLDS = {
      "A+" => 97, "A" => 93, "A-" => 90,
      "B+" => 87, "B" => 83, "B-" => 80,
      "C+" => 77, "C" => 73, "C-" => 70,
      "D+" => 67, "D" => 63, "D-" => 60,
      "F" => 0
    }.freeze

    LEVEL_LABELS = {
      "A+" => "최우수", "A" => "최우수", "A-" => "최우수",
      "B+" => "우수", "B" => "우수", "B-" => "우수",
      "C+" => "보통", "C" => "보통", "C-" => "보통",
      "D+" => "노력필요", "D" => "노력필요", "D-" => "노력필요",
      "F" => "집중지도"
    }.freeze

    def initialize(submission)
      @submission = submission
      @session = submission.session
    end

    # 전체 백분위 및 등급 계산
    def calculate
      domain_scores = @submission.metrics_result&.domain_scores_json || {}
      return empty_result if domain_scores.empty?

      # 비교 대상 점수 수집
      comparison_scores = collect_comparison_scores

      # 영역별 백분위 계산
      domain_percentiles = calculate_domain_percentiles(domain_scores, comparison_scores[:domain])

      # 전체 백분위 계산
      overall_score = domain_scores.values.sum.to_f / [domain_scores.count, 1].max
      overall_percentile = calculate_percentile_rank(overall_score, comparison_scores[:overall])

      # 등급 변환 (점수 기반으로 등급 산정)
      overall_grade = score_to_grade(overall_score)
      domain_grades = domain_scores.transform_values { |s| score_to_grade(s) }

      {
        overall: {
          score: overall_score.round(1),
          percentile: overall_percentile,
          grade: overall_grade,
          level: LEVEL_LABELS[overall_grade]
        },
        domains: domain_scores.keys.each_with_object({}) do |domain, hash|
          hash[domain] = {
            score: domain_scores[domain],
            percentile: domain_percentiles[domain] || 50,
            grade: domain_grades[domain] || "C",
            level: LEVEL_LABELS[domain_grades[domain] || "C"]
          }
        end,
        comparison_group: {
          session_id: @session&.id,
          sample_size: comparison_scores[:sample_size],
          grade_band: determine_grade_band
        }
      }
    end

    # 세션 내 학생들의 등급 분포 계산
    def calculate_grade_distribution
      return {} unless @session

      submissions = @session.submissions.where(status: "submitted")
        .includes(:metrics_result)

      distribution = Hash.new(0)

      submissions.each do |sub|
        metrics = sub.metrics_result
        next unless metrics&.domain_scores_json.present?

        avg_score = metrics.domain_scores_json.values.sum.to_f / metrics.domain_scores_json.count
        grade = score_to_grade(avg_score)
        distribution[grade] += 1
      end

      # 정렬된 형태로 반환
      GRADE_THRESHOLDS.keys.each_with_object({}) do |grade, hash|
        hash[grade] = distribution[grade]
      end
    end

    private

    def empty_result
      {
        overall: { score: 0, percentile: 0, grade: "F", level: "집중지도" },
        domains: {},
        comparison_group: { session_id: nil, sample_size: 0, grade_band: nil }
      }
    end

    # 비교 대상 점수 수집 (같은 세션 내 학생들)
    def collect_comparison_scores
      domain_scores_list = {}
      overall_scores = []

      if @session
        submissions = @session.submissions
          .where(status: "submitted")
          .includes(:metrics_result)

        submissions.each do |sub|
          metrics = sub.metrics_result
          next unless metrics&.domain_scores_json.present?

          domain_scores = metrics.domain_scores_json

          # 영역별 점수 수집
          domain_scores.each do |domain, score|
            domain_scores_list[domain] ||= []
            domain_scores_list[domain] << score
          end

          # 전체 점수 수집
          overall_scores << (domain_scores.values.sum.to_f / domain_scores.count)
        end
      end

      {
        domain: domain_scores_list,
        overall: overall_scores,
        sample_size: overall_scores.count
      }
    end

    # 영역별 백분위 계산
    def calculate_domain_percentiles(student_scores, comparison_scores)
      student_scores.each_with_object({}) do |(domain, score), hash|
        comparison = comparison_scores[domain] || []
        hash[domain] = calculate_percentile_rank(score, comparison)
      end
    end

    # 백분위 순위 계산
    # @param score [Float] 학생 점수
    # @param scores [Array<Float>] 비교 대상 점수 배열
    # @return [Integer] 백분위 (0-100)
    def calculate_percentile_rank(score, scores)
      return 50 if scores.empty? || scores.count < 2

      # 해당 점수보다 낮은 점수의 비율 계산
      below_count = scores.count { |s| s < score }
      equal_count = scores.count { |s| s == score }

      # 백분위 공식: (B + 0.5 * E) / N * 100
      percentile = ((below_count + 0.5 * equal_count) / scores.count.to_f * 100).round

      # 범위 제한
      [[percentile, 1].max, 99].min
    end

    # 점수/백분위를 등급으로 변환
    def score_to_grade(score)
      GRADE_THRESHOLDS.each do |grade, threshold|
        return grade if score >= threshold
      end
      "F"
    end

    # 학년군 결정
    def determine_grade_band
      student = @submission.student
      profile = student&.student_profile
      return nil unless profile&.school_class

      grade = profile.school_class.grade.to_i
      case grade
      when 1..2 then "초1-2"
      when 3..4 then "초3-4"
      when 5..6 then "초5-6"
      when 7..9 then "중등"
      when 10..12 then "고등"
      else nil
      end
    end
  end
end
