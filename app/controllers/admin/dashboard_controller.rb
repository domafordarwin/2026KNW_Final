module Admin
  class DashboardController < BaseController
    def index
      @stats = {
        users: User.count,
        passages: Passage.count,
        items: Item.count,
        assessment_versions: AssessmentVersion.count,
        books: BookCatalog.where(active: true).count
      }
    end
  end
end
