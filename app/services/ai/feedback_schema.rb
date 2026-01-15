module Ai
  class FeedbackSchema
    REQUIRED_KEYS = %w[executive_summary subskill_synthesis item_analysis integrated].freeze

    def self.required_keys
      REQUIRED_KEYS
    end
  end
end
