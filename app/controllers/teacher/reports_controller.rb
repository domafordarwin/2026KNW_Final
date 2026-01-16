module Teacher
  class ReportsController < BaseController
    before_action :set_report, only: [:show, :generate, :preview, :share, :download]

    def index
      @reports = Report.where(scope: "student").includes(submission: :student).order(created_at: :desc)
    end

    def show
      redirect_to report_path(@report)
    end

    def generate
      submission = Submission.find(params[:submission_id]) if params[:submission_id]

      unless submission
        redirect_to teacher_reports_path, alert: "제출물을 선택해주세요."
        return
      end

      report = Report.find_or_initialize_by(scope: "student", submission: submission)
      report.version = "1.0"
      report.status = "generated"
      report.template_version = "v1"
      report.save!

      redirect_to teacher_report_path(report), notice: "보고서가 생성되었습니다."
    end

    def preview
      redirect_to report_path(@report)
    end

    def download
      generator = Pdf::ReportGenerator.new(@report)
      pdf_data = generator.generate

      send_data pdf_data,
        filename: generator.filename,
        type: "application/pdf",
        disposition: "attachment"
    end

    def share
      access = ReportAccess.create!(
        report: @report,
        access_token: SecureRandom.urlsafe_base64(16),
        expires_at: 7.days.from_now
      )

      share_url = report_url(@report, token: access.access_token)
      redirect_to teacher_report_path(@report), notice: "공유 링크가 생성되었습니다: #{share_url}"
    end

    private

    def set_report
      @report = Report.find(params[:id])
    end
  end
end
