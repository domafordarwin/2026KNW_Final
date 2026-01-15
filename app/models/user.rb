class User < ApplicationRecord
  has_one :student_profile, foreign_key: :student_id, dependent: :destroy
  has_many :parent_links, foreign_key: :parent_user_id, dependent: :destroy
  has_many :student_parent_links, class_name: "ParentLink", foreign_key: :student_id, dependent: :destroy
end
