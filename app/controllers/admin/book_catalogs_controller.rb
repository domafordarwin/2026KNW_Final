module Admin
  class BookCatalogsController < BaseController
    before_action :set_book, only: [:show, :edit, :update, :destroy]

    def index
      @books = BookCatalog.order(created_at: :desc)
      @books = @books.where(active: params[:active] == "true") if params[:active].present?
      @books = @books.where(grade_band: params[:grade_band]) if params[:grade_band].present?
      @books = @books.where("title LIKE ?", "%#{params[:q]}%") if params[:q].present?
    end

    def show
    end

    def new
      @book = BookCatalog.new
    end

    def create
      @book = BookCatalog.new(book_params)
      if @book.save
        redirect_to admin_book_catalogs_path, notice: "도서가 추가되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @book.update(book_params)
        redirect_to admin_book_catalogs_path, notice: "도서 정보가 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @book.destroy
      redirect_to admin_book_catalogs_path, notice: "도서가 삭제되었습니다."
    end

    private

    def set_book
      @book = BookCatalog.find(params[:id])
    end

    def book_params
      params.require(:book_catalog).permit(
        :isbn, :title, :author, :grade_band, :difficulty, :tags_json, :active
      )
    end
  end
end
