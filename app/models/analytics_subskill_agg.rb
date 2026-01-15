class AnalyticsSubskillAgg < ApplicationRecord
  self.table_name = "analytics_subskill_agg"

  belongs_to :session
end
