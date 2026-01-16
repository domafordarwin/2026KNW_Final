module SchoolManager
  class StudentsController < BaseController
    before_action :set_student, only: [:show, :edit, :update, :destroy]

    def index
      @students = User.students.includes(:student_profile).order(:name)
      @students = @students.where("name LIKE ?", "%#{params[:q]}%") if params[:q].present?
    end

    def show
    end

    def new
      @student = User.new(role: "student")
    end

    def create
      @student = User.new(student_params)
      @student.role = "student"

      if @student.save
        create_student_profile(@student)
        redirect_to school_manager_students_path, notice: "학생이 등록되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      update_params = student_params
      update_params = update_params.except(:password, :password_confirmation) if update_params[:password].blank?

      if @student.update(update_params)
        redirect_to school_manager_students_path, notice: "학생 정보가 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @student.destroy
      redirect_to school_manager_students_path, notice: "학생이 삭제되었습니다."
    end

    def import
    end

    def create_import
      unless params[:file].present?
        flash[:alert] = "CSV 파일을 선택해주세요."
        return render :import, status: :unprocessable_entity
      end

      csv = CSV.parse(params[:file].read, headers: true)
      created = 0
      errors = []

      csv.each_with_index do |row, idx|
        user = User.new(
          name: row["name"],
          email_optional: row["email"],
          role: "student",
          status: "active",
          password: row["password"] || "changeme123"
        )

        if user.save
          StudentProfile.create(
            student: user,
            school_id: row["school_id"] || School.first&.id,
            class_id: row["class_id"] || SchoolClass.first&.id,
            student_code: row["student_code"] || "S#{user.id.to_s.rjust(5, '0')}"
          )
          created += 1
        else
          errors << "#{idx + 2}행: #{user.errors.full_messages.join(', ')}"
        end
      end

      if errors.any?
        flash[:alert] = "#{created}명 등록 완료. 오류: #{errors.first(3).join('; ')}"
      else
        flash[:notice] = "#{created}명의 학생이 성공적으로 등록되었습니다."
      end

      redirect_to school_manager_students_path
    end

    private

    def set_student
      @student = User.students.find(params[:id])
    end

    def student_params
      params.require(:user).permit(:name, :email_optional, :status, :password, :password_confirmation)
    end

    def create_student_profile(student)
      StudentProfile.create(
        student: student,
        school_id: School.first&.id || create_default_school.id,
        class_id: SchoolClass.first&.id || create_default_class.id,
        student_code: "S#{student.id.to_s.rjust(5, '0')}"
      )
    end

    def create_default_school
      School.create!(name: "Default School")
    end

    def create_default_class
      school = School.first || create_default_school
      SchoolClass.create!(school: school, grade: "1", name: "Default Class")
    end
  end
end
