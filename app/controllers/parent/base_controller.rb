module Parent
  class BaseController < ApplicationController
    before_action :require_parent!
    layout "parent"

    private

    def require_parent!
      require_role!("parent")
    end

    def linked_student_ids
      current_user.parent_links.pluck(:student_id)
    end
  end
end
