class ParentLink < ApplicationRecord
  belongs_to :parent_user, class_name: "User"
  belongs_to :student, class_name: "User"
end
