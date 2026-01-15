class Item < ApplicationRecord
  belongs_to :passage, optional: true
  has_many :responses, dependent: :destroy
  has_many :scoring_results, dependent: :destroy
  has_many :assessment_version_items, dependent: :destroy
  has_many :assessment_versions, through: :assessment_version_items
end
