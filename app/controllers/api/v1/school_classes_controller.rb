module Api
  module V1
    class SchoolClassesController < BaseController
      before_action -> { require_role!("admin", "teacher", "school_manager") }

      def index
        render json: SchoolClass.order(:id).limit(50)
      end

      def show
        render json: SchoolClass.find(params[:id])
      end
    end
  end
end
