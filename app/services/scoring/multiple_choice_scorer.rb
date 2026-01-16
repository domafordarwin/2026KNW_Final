module Scoring
  class MultipleChoiceScorer < BaseScorer
    def score(answer, item)
      answer_key = parse_answer_key(item.answer_key_json)
      normalized_answer = normalize_answer(answer)
      normalized_key = normalize_answer(answer_key)

      is_correct = normalized_answer == normalized_key

      {
        score: is_correct ? item.points : 0,
        is_correct: is_correct,
        rubric_breakdown: nil
      }
    end

    private

    def parse_answer_key(answer_key_json)
      return answer_key_json if answer_key_json.nil?

      # 이미 순수 문자열인 경우 (JSON 형식이 아닌 경우)
      if answer_key_json.is_a?(String) && !answer_key_json.start_with?("{", "[", '"')
        return answer_key_json
      end

      parsed = JSON.parse(answer_key_json)
      if parsed.is_a?(Hash)
        parsed["correct"] || parsed[:correct]
      else
        parsed
      end
    rescue JSON::ParserError
      answer_key_json
    end
  end
end
