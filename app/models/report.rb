class Report < ApplicationRecord
  belongs_to :submission, optional: true
  belongs_to :session, optional: true
  has_many :report_accesses, dependent: :destroy
end
