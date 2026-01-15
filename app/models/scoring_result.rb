class ScoringResult < ApplicationRecord
  belongs_to :submission
  belongs_to :item
end
