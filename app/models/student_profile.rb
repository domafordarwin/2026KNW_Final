class StudentProfile < ApplicationRecord
  belongs_to :student, class_name: "User"
  belongs_to :school
  belongs_to :school_class, class_name: "SchoolClass", foreign_key: :class_id
end
