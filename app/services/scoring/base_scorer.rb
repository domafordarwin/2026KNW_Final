module Scoring
  class BaseScorer
    def score(answer, item)
      raise NotImplementedError
    end

    protected

    def normalize_answer(answer)
      return "" if answer.nil?
      answer.to_s.strip.downcase
    end
  end
end
