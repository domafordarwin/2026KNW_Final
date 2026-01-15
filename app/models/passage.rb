class Passage < ApplicationRecord
  has_many :items, dependent: :destroy
end
