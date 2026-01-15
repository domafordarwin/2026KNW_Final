module Api
  module V1
    class SessionsController < BaseController
      def index
        render json: Session.order(:id).limit(50)
      end

      def show
        render json: Session.find(params[:id])
      end
    end
  end
end
