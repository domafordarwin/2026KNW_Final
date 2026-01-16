module SchoolManager
  class SchoolClassesController < BaseController
    before_action :set_class, only: [:show, :edit, :update, :destroy]

    def index
      @classes = SchoolClass.includes(:school).order(:grade, :name)
    end

    def show
      @students = @class.student_profiles.includes(:student)
    end

    def new
      @class = SchoolClass.new
    end

    def create
      @class = SchoolClass.new(class_params)
      if @class.save
        redirect_to school_manager_classes_path, notice: "Class created"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @class.update(class_params)
        redirect_to school_manager_classes_path, notice: "Class updated"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @class.destroy
      redirect_to school_manager_classes_path, notice: "Class deleted"
    end

    private

    def set_class
      @class = SchoolClass.find(params[:id])
    end

    def class_params
      params.require(:school_class).permit(:school_id, :grade, :name)
    end
  end
end
