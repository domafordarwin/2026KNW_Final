class TeacherFeedbacksController < ApplicationController
  before_action -> { require_role!("teacher", "admin") }
  before_action :set_submission

  def show
    @teacher_feedback = TeacherFeedback.find_or_initialize_by(
      submission: @submission,
      editor_teacher: current_user
    )
    @compiled_json = @submission.ai_feedback_compiled&.compiled_json || {}
  end

  def update
    @teacher_feedback = TeacherFeedback.find_or_initialize_by(
      submission: @submission,
      editor_teacher: current_user
    )

    payload, parse_error = parse_json(params[:content_json])
    if parse_error
      flash.now[:alert] = parse_error
      @compiled_json = @submission.ai_feedback_compiled&.compiled_json || {}
      return render :show, status: :unprocessable_entity
    end

    approve = params[:commit] == "Approve"
    @teacher_feedback.content_json = payload
    @teacher_feedback.status = approve ? "approved" : "draft"
    @teacher_feedback.approved_at = approve ? Time.current : nil

    if approve
      compiler = Ai::FeedbackCompiler.new
      merged, errors = compiler.compile(@submission.ai_feedback_compiled&.compiled_json || {}, payload)
      if errors.any?
        flash.now[:alert] = "Validation failed: #{errors.join(', ')}"
        @teacher_feedback.status = "draft"
        @teacher_feedback.approved_at = nil
        @compiled_json = @submission.ai_feedback_compiled&.compiled_json || {}
        return render :show, status: :unprocessable_entity
      end
    end

    @teacher_feedback.save!
    redirect_to submission_teacher_feedback_path(@submission), notice: "Saved"
  end

  private

  def set_submission
    @submission = Submission.find(params[:submission_id])
  end

  def parse_json(text)
    return [{}, nil] if text.blank?

    begin
      [JSON.parse(text), nil]
    rescue JSON::ParserError => e
      [nil, "Invalid JSON: #{e.message}"]
    end
  end
end
