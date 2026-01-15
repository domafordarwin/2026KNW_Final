class AnalyticsDomainAgg < ApplicationRecord
  self.table_name = "analytics_domain_agg"

  belongs_to :session
  belongs_to :school_class, class_name: "SchoolClass", foreign_key: :class_id, optional: true
end
