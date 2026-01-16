module Scoring
  class EssayScorer < BaseScorer
    def score(answer, item)
      rubric = parse_rubric(item.rubric_json)
      return default_score(item) if rubric.blank? || answer.blank?

      criteria_scores = score_criteria(answer, rubric)
      total_score = criteria_scores.sum { |c| c[:score] }
      max_score = criteria_scores.sum { |c| c[:max_score] }

      ratio = max_score.zero? ? 0 : (total_score.to_f / max_score)
      final_score = (ratio * item.points).round

      {
        score: final_score,
        is_correct: ratio >= 0.5,
        rubric_breakdown: {
          criteria: criteria_scores,
          total_score: total_score,
          max_score: max_score
        }
      }
    end

    private

    def parse_rubric(rubric_json)
      return nil if rubric_json.blank?

      parsed = JSON.parse(rubric_json)
      parsed["criteria"] || parsed
    rescue JSON::ParserError
      nil
    end

    def score_criteria(answer, rubric)
      criteria = rubric.is_a?(Array) ? rubric : []
      word_count = answer.to_s.split.count

      criteria.map do |criterion|
        name = criterion["name"] || criterion["criterion"]
        max_score = criterion["max_score"] || criterion["points"] || 1

        # Simple heuristic scoring based on response length and criterion
        score = calculate_criterion_score(answer, name, max_score, word_count)

        {
          criterion: name,
          score: score,
          max_score: max_score
        }
      end
    end

    def calculate_criterion_score(answer, criterion_name, max_score, word_count)
      # Heuristic scoring - in production, this would use LLM
      base_score = case criterion_name.to_s.downcase
      when /content|ideas|understanding/
        word_count >= 50 ? max_score : (word_count / 50.0 * max_score).round
      when /organization|structure/
        answer.to_s.include?("\n") || word_count >= 30 ? max_score : (max_score * 0.5).round
      when /language|grammar|mechanics/
        max_score # Assume acceptable without deeper analysis
      when /evidence|support/
        word_count >= 40 ? max_score : (word_count / 40.0 * max_score).round
      else
        (max_score * 0.7).round
      end

      [base_score, max_score].min
    end

    def default_score(item)
      {
        score: 0,
        is_correct: false,
        rubric_breakdown: nil
      }
    end
  end
end
