module Parent
  class DashboardController < BaseController
    def index
      @children = User.where(id: linked_student_ids)
    end
  end
end
