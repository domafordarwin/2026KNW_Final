class AssessmentVersionItem < ApplicationRecord
  belongs_to :assessment_version
  belongs_to :item
end
