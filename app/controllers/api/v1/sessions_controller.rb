module Api
  module V1
    class SessionsController < BaseController
      before_action -> { require_role!("admin", "teacher", "school_manager") }

      def index
        render json: Session.order(:id).limit(50)
      end

      def show
        render json: Session.find(params[:id])
      end
    end
  end
end
