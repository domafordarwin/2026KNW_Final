class ReportPresenter
  attr_reader :report

  def initialize(report)
    @report = report
  end

  def student_report?
    report.scope == "student"
  end

  def school_report?
    report.scope == "school"
  end

  def submission
    report.submission
  end

  def session
    report.session || submission&.session
  end

  def student
    submission&.student
  end

  def school_class
    session&.school_class
  end

  def school
    session&.school
  end

  def assessment_version
    session&.assessment_version
  end

  def assessment_items
    assessment_version&.items || []
  end

  def assessment_domains
    assessment_items.map(&:domain).compact.uniq
  end

  def assessment_subskills
    assessment_items.map(&:subskill).compact.uniq
  end

  def metrics_result
    submission&.metrics_result
  end

  def domain_scores
    metrics_result&.domain_scores_json || {}
  end

  def subskill_scores
    metrics_result&.subskill_scores_json || {}
  end

  def trait_result
    submission&.trait_result
  end

  def compiled_feedback
    submission&.ai_feedback_compiled&.compiled_json || {}
  end

  def teacher_feedback
    submission&.teacher_feedback
  end

  def merged_feedback
    base = deep_dup(compiled_feedback)
    return base unless teacher_feedback&.status == "approved"

    deep_merge(base, teacher_feedback.content_json || {})
  end

  def item_analysis
    merged_feedback.fetch("item_analysis", [])
  end

  def item_rows
    return [] unless submission

    scoring_by_item = submission.scoring_results.index_by(&:item_id)
    submission.responses.includes(:item).map do |response|
      item = response.item
      scoring = scoring_by_item[item.id]
      {
        item_id: item.id,
        prompt: item.prompt,
        score: scoring&.score,
        is_correct: scoring&.is_correct,
        answer: response.answer_json,
        time_spent: response.time_spent
      }
    end
  end

  def rubric_feedback
    return [] unless submission

    submission.scoring_results.filter_map do |result|
      next if result.rubric_breakdown_json.blank?

      { item_id: result.item_id, rubric: result.rubric_breakdown_json }
    end
  end

  def subskill_synthesis
    merged_feedback.fetch("subskill_synthesis", {})
  end

  def executive_summary
    merged_feedback["executive_summary"]
  end

  def domain_guidance
    merged_feedback.dig("integrated", "domain_guidance") || {}
  end

  def parent_summary
    merged_feedback.dig("integrated", "parent_summary") || merged_feedback["parent_summary"]
  end

  def book_guidance
    submission&.book_guidance
  end

  def selected_books
    ids = book_guidance&.selected_book_ids_json || []
    BookCatalog.where(id: ids)
  end

  def participation_stats
    return {} unless session

    total = session.submissions.count
    submitted = session.submissions.where(status: "submitted").count
    {
      total: total,
      submitted: submitted,
      submission_rate: total.zero? ? 0 : ((submitted.to_f / total) * 100).round(1)
    }
  end

  def domain_aggs
    AnalyticsDomainAgg.where(session: session).order(:domain)
  end

  def subskill_aggs
    AnalyticsSubskillAgg.where(session: session).order(:subskill)
  end

  def trait_aggs
    AnalyticsTraitAgg.where(session: session).order(:trait_type)
  end

  private

  def deep_merge(target, source)
    source.each do |key, value|
      if target[key].is_a?(Hash) && value.is_a?(Hash)
        deep_merge(target[key], value)
      else
        target[key] = value
      end
    end
    target
  end

  def deep_dup(value)
    case value
    when Hash
      value.transform_values { |v| deep_dup(v) }
    when Array
      value.map { |v| deep_dup(v) }
    else
      value
    end
  end
end
