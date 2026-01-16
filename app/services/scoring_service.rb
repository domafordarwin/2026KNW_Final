class ScoringService
  def initialize(submission)
    @submission = submission
  end

  def score_all
    @submission.responses.includes(:item).each do |response|
      score_response(response)
    end

    calculate_metrics
    determine_trait
  end

  private

  def score_response(response)
    item = response.item
    scorer = scorer_for(item)
    result = scorer.score(response.answer_json, item)

    ScoringResult.find_or_initialize_by(
      submission: @submission,
      item: item
    ).update!(
      score: result[:score],
      is_correct: result[:is_correct],
      rubric_breakdown_json: result[:rubric_breakdown]
    )
  end

  def scorer_for(item)
    case item.item_type
    when "multiple_choice"
      Scoring::MultipleChoiceScorer.new
    when "short_answer"
      Scoring::ShortAnswerScorer.new
    when "essay"
      Scoring::EssayScorer.new
    else
      Scoring::DefaultScorer.new
    end
  end

  def calculate_metrics
    results = @submission.scoring_results.includes(:item)
    items = results.map(&:item)

    domain_scores = calculate_domain_scores(results, items)
    subskill_scores = calculate_subskill_scores(results, items)
    percentiles = calculate_percentiles(domain_scores)

    MetricsResult.find_or_initialize_by(submission: @submission).update!(
      domain_scores_json: domain_scores,
      subskill_scores_json: subskill_scores,
      percentile_json: percentiles,
      computed_at: Time.current
    )
  end

  def calculate_domain_scores(results, items)
    domain_items = items.group_by(&:domain)
    domain_items.transform_values do |domain_item_list|
      domain_results = results.select { |r| domain_item_list.map(&:id).include?(r.item_id) }
      total_points = domain_item_list.sum(&:points)
      earned_points = domain_results.sum(&:score)

      next 0 if total_points.zero?
      ((earned_points.to_f / total_points) * 100).round(1)
    end.compact
  end

  def calculate_subskill_scores(results, items)
    subskill_items = items.group_by(&:subskill)
    subskill_items.transform_values do |subskill_item_list|
      next nil if subskill_item_list.first.nil?

      subskill_results = results.select { |r| subskill_item_list.map(&:id).include?(r.item_id) }
      total_points = subskill_item_list.sum(&:points)
      earned_points = subskill_results.sum(&:score)

      next 0 if total_points.zero?
      ((earned_points.to_f / total_points) * 100).round(1)
    end.compact
  end

  def calculate_percentiles(domain_scores)
    # 향상된 백분위 계산기 사용
    calculator = Scoring::PercentileCalculator.new(@submission)
    result = calculator.calculate

    # 기존 형식 유지하면서 영역별 백분위 반환
    percentiles = result[:domains].transform_values { |d| d[:percentile] }

    # 전체 백분위 추가
    percentiles["overall"] = result[:overall][:percentile]

    percentiles
  end

  public

  # 등급 정보 조회 (외부에서 호출 가능)
  def grade_info
    calculator = Scoring::PercentileCalculator.new(@submission)
    calculator.calculate
  end

  private

  def determine_trait
    metrics = @submission.metrics_result
    return unless metrics

    domain_scores = metrics.domain_scores_json || {}

    # Rule-based trait determination (A-D)
    trait_type = calculate_trait_type(domain_scores)
    trait_scores = {
      comprehension: domain_scores["comprehension"] || 0,
      vocabulary: domain_scores["vocabulary"] || 0,
      inference: domain_scores["inference"] || 0,
      analysis: domain_scores["analysis"] || 0
    }

    TraitResult.find_or_initialize_by(submission: @submission).update!(
      trait_type: trait_type,
      trait_scores_json: trait_scores,
      computed_at: Time.current
    )
  end

  def calculate_trait_type(domain_scores)
    avg = domain_scores.values.sum.to_f / [domain_scores.values.count, 1].max

    comprehension = domain_scores["comprehension"] || 0
    inference = domain_scores["inference"] || 0

    # Type A: Strong across all domains
    return "A" if avg >= 80

    # Type B: Strong comprehension, weaker inference
    return "B" if comprehension >= 70 && inference < 60

    # Type C: Balanced but moderate
    return "C" if avg >= 50 && avg < 80

    # Type D: Needs significant support
    "D"
  end
end
