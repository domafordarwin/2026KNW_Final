module SchoolManager
  class BaseController < ApplicationController
    before_action :require_school_manager!
    layout "school_manager"

    private

    def require_school_manager!
      require_role!("school_manager", "admin")
    end
  end
end
