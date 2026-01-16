module Admin
  class AssessmentVersionsController < BaseController
    before_action :set_assessment_version, only: [:show, :edit, :update, :destroy, :publish]

    def index
      @assessment_versions = AssessmentVersion.order(created_at: :desc)
    end

    def show
      @items = @assessment_version.items.includes(:passage)
    end

    def new
      @assessment_version = AssessmentVersion.new
      @available_items = Item.all
    end

    def create
      @assessment_version = AssessmentVersion.new(assessment_version_params)
      @assessment_version.status = "draft"

      if @assessment_version.save
        update_items
        redirect_to admin_assessment_version_path(@assessment_version), notice: "평가 버전이 생성되었습니다."
      else
        @available_items = Item.all
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @available_items = Item.all
    end

    def update
      if @assessment_version.status == "published"
        redirect_to admin_assessment_version_path(@assessment_version), alert: "배포된 버전은 수정할 수 없습니다."
        return
      end

      if @assessment_version.update(assessment_version_params)
        update_items
        redirect_to admin_assessment_version_path(@assessment_version), notice: "평가 버전이 수정되었습니다."
      else
        @available_items = Item.all
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @assessment_version.status == "published"
        redirect_to admin_assessment_versions_path, alert: "배포된 버전은 삭제할 수 없습니다."
        return
      end

      @assessment_version.destroy
      redirect_to admin_assessment_versions_path, notice: "평가 버전이 삭제되었습니다."
    end

    def publish
      if @assessment_version.items.empty?
        redirect_to admin_assessment_version_path(@assessment_version), alert: "문항이 없는 버전은 배포할 수 없습니다."
        return
      end

      @assessment_version.update!(status: "published", published_at: Time.current)
      redirect_to admin_assessment_version_path(@assessment_version), notice: "평가 버전이 배포되었습니다."
    end

    private

    def set_assessment_version
      @assessment_version = AssessmentVersion.find(params[:id])
    end

    def assessment_version_params
      params.require(:assessment_version).permit(:name)
    end

    def update_items
      return unless params[:item_ids].present?

      @assessment_version.assessment_version_items.destroy_all
      params[:item_ids].each_with_index do |item_id, index|
        @assessment_version.assessment_version_items.create!(
          item_id: item_id,
          order_no: index + 1
        )
      end
    end
  end
end
