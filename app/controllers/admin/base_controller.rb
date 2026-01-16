module Admin
  class BaseController < ApplicationController
    before_action :require_admin!
    layout "admin"

    private

    def require_admin!
      require_role!("admin")
    end
  end
end
