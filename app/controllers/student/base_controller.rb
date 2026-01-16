module Student
  class BaseController < ApplicationController
    before_action :require_student!
    layout "student"

    private

    def require_student!
      require_role!("student")
    end
  end
end
