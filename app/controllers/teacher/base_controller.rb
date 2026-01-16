module Teacher
  class BaseController < ApplicationController
    before_action :require_teacher!
    layout "teacher"

    private

    def require_teacher!
      require_role!("teacher", "admin")
    end
  end
end
