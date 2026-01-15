module Api
  module V1
    class ItemsController < BaseController
      def index
        render json: Item.order(:id).limit(50)
      end

      def show
        render json: Item.find(params[:id])
      end
    end
  end
end
