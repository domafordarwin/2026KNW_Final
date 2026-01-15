class SchoolClass < ApplicationRecord
  self.table_name = "classes"

  belongs_to :school
  has_many :student_profiles, foreign_key: :class_id, dependent: :destroy
  has_many :sessions, foreign_key: :class_id, dependent: :destroy
end
