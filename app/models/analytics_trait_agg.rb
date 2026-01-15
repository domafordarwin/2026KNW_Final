class AnalyticsTraitAgg < ApplicationRecord
  self.table_name = "analytics_trait_agg"

  belongs_to :session
end
