module Teacher
  class FeedbacksController < BaseController
    before_action :set_submission, only: [:show, :update, :approve, :regenerate_section]

    def index
      @feedbacks = TeacherFeedback.includes(submission: [:student, :session]).order(created_at: :desc)
      @feedbacks = @feedbacks.where(status: params[:status]) if params[:status].present?

      @pending_submissions = Submission.where(status: "submitted")
        .left_joins(:teacher_feedback)
        .where(teacher_feedback: { id: nil })
    end

    def show
      @teacher_feedback = TeacherFeedback.find_or_initialize_by(
        submission: @submission,
        editor_teacher: current_user
      )
      @ai_feedback = @submission.ai_feedback_compiled&.compiled_json || {}
    end

    def update
      @teacher_feedback = TeacherFeedback.find_or_initialize_by(
        submission: @submission,
        editor_teacher: current_user
      )

      payload, error = parse_json(params[:content_json])
      if error
        flash[:alert] = error
        @ai_feedback = @submission.ai_feedback_compiled&.compiled_json || {}
        return render :show, status: :unprocessable_entity
      end

      # AI 원본과 비교하여 diff_json 생성
      ai_original = @submission.ai_feedback_compiled&.compiled_json || {}
      diff = generate_diff(ai_original, payload)

      @teacher_feedback.content_json = payload
      @teacher_feedback.diff_json = diff
      @teacher_feedback.status = "draft"
      @teacher_feedback.save!

      create_audit("save_draft")
      redirect_to teacher_submission_feedback_path(@submission), notice: "초안이 저장되었습니다."
    end

    def approve
      @teacher_feedback = TeacherFeedback.find_by!(submission: @submission)

      compiler = Ai::FeedbackCompiler.new
      ai_json = @submission.ai_feedback_compiled&.compiled_json || {}
      merged, errors = compiler.compile(ai_json, @teacher_feedback.content_json || {})

      if errors.any?
        redirect_to teacher_submission_feedback_path(@submission), alert: "검증 오류: #{errors.join(', ')}"
        return
      end

      @teacher_feedback.update!(status: "approved", approved_at: Time.current)
      create_audit("approve")

      redirect_to teacher_submission_feedback_path(@submission), notice: "피드백이 승인되어 잠금 처리되었습니다."
    end

    def regenerate_section
      section = params[:section]

      # LLM 재생성 작업 큐에 추가
      FeedbackPipelineJob.perform_later(@submission.id, section: section)

      redirect_to teacher_submission_feedback_path(@submission), notice: "#{section_label(section)} 섹션 재생성이 요청되었습니다."
    end

    private

    def set_submission
      @submission = Submission.find(params[:submission_id])
    end

    def parse_json(text)
      return [{}, nil] if text.blank?
      [JSON.parse(text), nil]
    rescue JSON::ParserError => e
      [nil, "잘못된 JSON 형식: #{e.message}"]
    end

    def create_audit(action)
      FeedbackAudit.create!(
        teacher_feedback: @teacher_feedback,
        actor: current_user,
        action: action,
        timestamp: Time.current,
        meta_json: {
          status: @teacher_feedback.status,
          diff_summary: summarize_diff(@teacher_feedback.diff_json)
        }
      )
    end

    # AI 원본과 교사 편집본의 차이점을 생성
    def generate_diff(original, edited)
      return {} unless original.is_a?(Hash) && edited.is_a?(Hash)

      diff = {}
      all_keys = (original.keys + edited.keys).uniq

      all_keys.each do |key|
        next if key == '_annotations' # 주석은 diff에서 제외

        orig_val = original[key]
        edit_val = edited[key]

        if orig_val != edit_val
          diff[key] = {
            'original' => orig_val,
            'edited' => edit_val,
            'changed_at' => Time.current.iso8601
          }
        end
      end

      diff
    end

    # diff 요약 생성 (감사 로그용)
    def summarize_diff(diff_json)
      return nil unless diff_json.is_a?(Hash)
      return nil if diff_json.empty?

      changed_keys = diff_json.keys
      "수정된 섹션: #{changed_keys.join(', ')}"
    end

    # 섹션 키를 한글 라벨로 변환
    def section_label(key)
      labels = {
        'executive_summary' => '종합 요약',
        'subskill_synthesis' => '하위 영역 분석',
        'item_analysis' => '문항별 분석',
        'trait_explanation' => '독자 성향 설명',
        'integrated.domain_guidance' => '영역별 학습 지도',
        'integrated.book_guidance' => '도서 추천',
        'integrated.parent_summary' => '학부모 요약'
      }
      labels[key] || key
    end
  end
end
