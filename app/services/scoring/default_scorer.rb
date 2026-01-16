module Scoring
  class DefaultScorer < BaseScorer
    def score(answer, item)
      {
        score: 0,
        is_correct: false,
        rubric_breakdown: nil
      }
    end
  end
end
