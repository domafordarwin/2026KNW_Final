class AssessmentVersion < ApplicationRecord
  has_many :assessment_version_items, dependent: :destroy
  has_many :items, through: :assessment_version_items
  has_many :sessions, dependent: :destroy
end
