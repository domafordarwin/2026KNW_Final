class Session < ApplicationRecord
  belongs_to :school
  belongs_to :school_class, class_name: "SchoolClass", foreign_key: :class_id
  belongs_to :assessment_version
  belongs_to :created_by_teacher, class_name: "User"

  has_many :submissions, dependent: :destroy
  has_many :reports, dependent: :destroy
end
