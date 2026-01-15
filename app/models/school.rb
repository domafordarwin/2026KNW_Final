class School < ApplicationRecord
  has_many :school_classes, class_name: "SchoolClass", dependent: :destroy
  has_many :student_profiles, dependent: :destroy
  has_many :sessions, dependent: :destroy
end
