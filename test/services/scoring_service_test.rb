require "test_helper"

class ScoringServiceTest < ActiveSupport::TestCase
  setup do
    @school = create_school
    @school_class = create_class(@school)
    @teacher = create_teacher
    @student = create_student

    @passage = Passage.create!(title: "Test Passage", text: "Test content")
    @item_mc = Item.create!(
      passage: @passage,
      item_type: "multiple_choice",
      domain: "comprehension",
      subskill: "main_idea",
      prompt: "What is the main idea?",
      choices_json: '["A", "B", "C", "D"]',
      answer_key_json: '"B"',
      points: 1
    )
    @item_short = Item.create!(
      passage: @passage,
      item_type: "short_answer",
      domain: "vocabulary",
      subskill: "context_clues",
      prompt: "Define the word.",
      answer_key_json: '["meaning", "definition"]',
      points: 2
    )

    @version = AssessmentVersion.create!(name: "Test Version", status: "published")
    AssessmentVersionItem.create!(assessment_version: @version, item: @item_mc, order_no: 1)
    AssessmentVersionItem.create!(assessment_version: @version, item: @item_short, order_no: 2)

    @session = Session.create!(
      school: @school,
      school_class: @school_class,
      assessment_version: @version,
      created_by_teacher: @teacher,
      status: "active",
      access_code: "ABC123"
    )

    @submission = Submission.create!(
      session: @session,
      student: @student,
      status: "submitted",
      started_at: 1.hour.ago,
      submitted_at: Time.current
    )
  end

  test "scores multiple choice correctly" do
    Response.create!(submission: @submission, item: @item_mc, answer_json: "B")

    ScoringService.new(@submission).score_all

    result = ScoringResult.find_by(submission: @submission, item: @item_mc)
    assert result.is_correct
    assert_equal 1, result.score
  end

  test "scores multiple choice incorrectly" do
    Response.create!(submission: @submission, item: @item_mc, answer_json: "A")

    ScoringService.new(@submission).score_all

    result = ScoringResult.find_by(submission: @submission, item: @item_mc)
    assert_not result.is_correct
    assert_equal 0, result.score
  end

  test "scores short answer with keyword matching" do
    Response.create!(submission: @submission, item: @item_short, answer_json: "The meaning of the word is clear")

    ScoringService.new(@submission).score_all

    result = ScoringResult.find_by(submission: @submission, item: @item_short)
    assert result.score > 0
    assert result.rubric_breakdown_json.present?
  end

  test "calculates metrics result" do
    Response.create!(submission: @submission, item: @item_mc, answer_json: "B")
    Response.create!(submission: @submission, item: @item_short, answer_json: "meaning definition")

    ScoringService.new(@submission).score_all

    metrics = @submission.reload.metrics_result
    assert metrics.present?
    assert metrics.domain_scores_json.present?
    assert metrics.subskill_scores_json.present?
  end

  test "determines trait result" do
    Response.create!(submission: @submission, item: @item_mc, answer_json: "B")
    Response.create!(submission: @submission, item: @item_short, answer_json: "meaning")

    ScoringService.new(@submission).score_all

    trait = @submission.reload.trait_result
    assert trait.present?
    assert %w[A B C D].include?(trait.trait_type)
  end
end
