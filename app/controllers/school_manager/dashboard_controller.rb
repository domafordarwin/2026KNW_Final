module SchoolManager
  class DashboardController < BaseController
    def index
      # 기본 통계
      @stats = calculate_basic_stats

      # 최근 세션들
      @recent_sessions = Session.includes(:school, :assessment_version)
                                .order(created_at: :desc)
                                .limit(5)

      # 영역별 통계 (모든 세션 집계)
      @domain_stats = calculate_domain_stats

      # 학급별 참여율
      @class_participation = calculate_class_participation

      # 최근 제출물
      @recent_submissions = Submission.includes(:student, session: :assessment_version)
                                      .where(status: "submitted")
                                      .order(submitted_at: :desc)
                                      .limit(10)

      # 등급 분포
      @grade_distribution = calculate_grade_distribution

      # 취약 영역 분석
      @weak_areas = calculate_weak_areas
    end

    private

    def calculate_basic_stats
      total_students = User.students.count
      completed_submissions = Submission.where(status: "submitted").count
      total_submissions = Submission.count

      {
        students: total_students,
        classes: SchoolClass.count,
        sessions: Session.count,
        active_sessions: Session.where(status: "active").count,
        reports: Report.count,
        school_reports: Report.where(scope: "school").count,
        student_reports: Report.where(scope: "student").count,
        submissions_total: total_submissions,
        submissions_completed: completed_submissions,
        completion_rate: total_submissions > 0 ? (completed_submissions.to_f / total_submissions * 100).round(1) : 0,
        average_score: calculate_average_score
      }
    end

    def calculate_average_score
      results = ScoringResult.joins(:submission).where(submissions: { status: "submitted" })
      return 0 unless results.any?

      total_score = results.sum(:score)
      total_items = results.count
      return 0 if total_items == 0

      (total_score.to_f / total_items * 100).round(1)
    end

    def calculate_domain_stats
      # 영역별 평균 점수 집계
      AnalyticsDomainAgg.select(:domain)
                        .group(:domain)
                        .average(:avg)
                        .transform_values { |v| v&.round(1) || 0 }
    end

    def calculate_class_participation
      SchoolClass.includes(:student_profiles).map do |school_class|
        student_ids = school_class.student_profiles.pluck(:student_id)
        total_students = student_ids.count
        next nil if total_students == 0

        submitted_count = Submission.where(student_id: student_ids, status: "submitted").count

        {
          name: school_class.name,
          grade: school_class.grade,
          total: total_students,
          submitted: submitted_count,
          rate: (submitted_count.to_f / total_students * 100).round(1)
        }
      end.compact
    end

    def calculate_grade_distribution
      # 등급별 학생 수 분포
      metrics = MetricsResult.includes(:submission).all
      return {} unless metrics.any?

      distribution = { "A" => 0, "B" => 0, "C" => 0, "D" => 0, "F" => 0 }

      metrics.each do |m|
        percentile = m.percentile_json&.dig("overall") || 50
        grade = percentile_to_grade(percentile)
        distribution[grade] += 1
      end

      distribution
    end

    def percentile_to_grade(percentile)
      case percentile.to_f
      when 90..100 then "A"
      when 80..89 then "B"
      when 70..79 then "C"
      when 60..69 then "D"
      else "F"
      end
    end

    def calculate_weak_areas
      AnalyticsSubskillAgg.select(:subskill)
                          .group(:subskill)
                          .average(:avg)
                          .sort_by { |_, v| v || 0 }
                          .first(5)
                          .map { |k, v| { subskill: k, avg: v&.round(1) || 0 } }
    end
  end
end
