module Api
  module V1
    class BaseController < ActionController::API
      include RoleAuthorization

      before_action :load_current_user

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: "not_found" }, status: :not_found
      end

      private

      def load_current_user
        user_id = request.headers["X-User-Id"]
        @current_user = user_id.present? ? User.find_by(id: user_id) : nil
      end

      def current_user
        @current_user
      end
    end
  end
end
