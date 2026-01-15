class BookGuidance < ApplicationRecord
  self.table_name = "book_guidance"

  belongs_to :submission
end
