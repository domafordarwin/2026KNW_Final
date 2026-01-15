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

  def metrics_result
    submission&.metrics_result
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
