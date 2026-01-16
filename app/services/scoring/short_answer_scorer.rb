module Scoring
  class ShortAnswerScorer < BaseScorer
    def score(answer, item)
      keywords = parse_keywords(item.answer_key_json)
      normalized_answer = normalize_answer(answer)

      matched_keywords = keywords.count { |kw| normalized_answer.include?(normalize_answer(kw)) }
      match_ratio = keywords.empty? ? 0 : (matched_keywords.to_f / keywords.count)

      score = (match_ratio * item.points).round
      is_correct = match_ratio >= 0.5

      {
        score: score,
        is_correct: is_correct,
        rubric_breakdown: {
          total_keywords: keywords.count,
          matched_keywords: matched_keywords,
          match_ratio: match_ratio.round(2)
        }
      }
    end

    private

    def parse_keywords(answer_key_json)
      return [] if answer_key_json.blank?

      parsed = JSON.parse(answer_key_json)
      parsed.is_a?(Array) ? parsed : [parsed]
    rescue JSON::ParserError
      answer_key_json.to_s.split(",").map(&:strip)
    end
  end
end
