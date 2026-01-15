module Api
  module V1
    class SchoolsController < BaseController
      before_action -> { require_role!("admin", "teacher", "school_manager") }

      def index
        render json: School.order(:id).limit(50)
      end

      def show
        render json: School.find(params[:id])
      end
    end
  end
end
