module Admin
  class ItemsController < BaseController
    before_action :set_passage, only: [:new, :create, :show, :edit, :update, :destroy]
    before_action :set_item, only: [:show, :edit, :update, :destroy]

    def index
      @items = Item.includes(:passage).order(created_at: :desc)
      @items = @items.where(domain: params[:domain]) if params[:domain].present?
      @items = @items.where(subskill: params[:subskill]) if params[:subskill].present?
      @items = @items.where(item_type: params[:item_type]) if params[:item_type].present?
      @items = @items.where(difficulty: params[:difficulty]) if params[:difficulty].present?
    end

    def show
    end

    def new
      @item = @passage.items.build
    end

    def create
      @item = @passage.items.build(item_params)
      if @item.save
        redirect_to admin_passage_path(@passage), notice: "문항이 생성되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @item.update(item_params)
        redirect_to admin_passage_path(@passage), notice: "문항이 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @item.destroy
      redirect_to admin_passage_path(@passage), notice: "문항이 삭제되었습니다."
    end

    private

    def set_passage
      @passage = Passage.find(params[:passage_id]) if params[:passage_id]
    end

    def set_item
      @item = @passage ? @passage.items.find(params[:id]) : Item.find(params[:id])
    end

    def item_params
      params.require(:item).permit(
        :item_type, :domain, :subskill, :difficulty,
        :prompt, :choices_json, :answer_key_json, :rubric_json, :points
      )
    end
  end
end
