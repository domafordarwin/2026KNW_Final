require "test_helper"

class ShortAnswerScorerTest < ActiveSupport::TestCase
  setup do
    @scorer = Scoring::ShortAnswerScorer.new
    @item = Item.new(points: 2, answer_key_json: '["main", "idea", "theme"]')
  end

  test "full match scores full points" do
    result = @scorer.score("The main idea and theme", @item)

    assert result[:is_correct]
    assert_equal 2, result[:score]
  end

  test "partial match scores partial points" do
    result = @scorer.score("The main point", @item)

    assert result[:rubric_breakdown][:matched_keywords] >= 1
  end

  test "no match scores zero" do
    result = @scorer.score("Something completely different", @item)

    assert_not result[:is_correct]
    assert_equal 0, result[:score]
  end

  test "rubric breakdown includes keyword info" do
    result = @scorer.score("main idea", @item)

    assert_equal 3, result[:rubric_breakdown][:total_keywords]
    assert result[:rubric_breakdown][:matched_keywords] >= 2
  end

  test "handles comma-separated answer key" do
    @item.answer_key_json = "main, idea, theme"
    result = @scorer.score("The main idea", @item)

    assert result[:rubric_breakdown][:matched_keywords] >= 2
  end
end
