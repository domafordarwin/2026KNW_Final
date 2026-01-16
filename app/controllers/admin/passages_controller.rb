module Admin
  class PassagesController < BaseController
    before_action :set_passage, only: [:show, :edit, :update, :destroy]

    def index
      @passages = Passage.order(created_at: :desc)
      @passages = @passages.where("grade_band = ?", params[:grade_band]) if params[:grade_band].present?
      @passages = @passages.where("title LIKE ?", "%#{params[:q]}%") if params[:q].present?
    end

    def show
      @items = @passage.items
    end

    def new
      @passage = Passage.new
    end

    def create
      @passage = Passage.new(passage_params)
      if @passage.save
        redirect_to admin_passage_path(@passage), notice: "지문이 생성되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @passage.update(passage_params)
        redirect_to admin_passage_path(@passage), notice: "지문이 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @passage.destroy
      redirect_to admin_passages_path, notice: "지문이 삭제되었습니다."
    end

    private

    def set_passage
      @passage = Passage.find(params[:id])
    end

    def passage_params
      params.require(:passage).permit(:title, :text, :grade_band, :tags_json)
    end
  end
end
