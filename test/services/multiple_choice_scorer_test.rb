require "test_helper"

class MultipleChoiceScorerTest < ActiveSupport::TestCase
  setup do
    @scorer = Scoring::MultipleChoiceScorer.new
    @item = Item.new(points: 1, answer_key_json: '"B"')
  end

  test "correct answer scores full points" do
    result = @scorer.score("B", @item)

    assert result[:is_correct]
    assert_equal 1, result[:score]
  end

  test "incorrect answer scores zero" do
    result = @scorer.score("A", @item)

    assert_not result[:is_correct]
    assert_equal 0, result[:score]
  end

  test "case insensitive matching" do
    result = @scorer.score("b", @item)

    assert result[:is_correct]
  end

  test "handles JSON object answer key" do
    @item.answer_key_json = '{"correct": "C"}'
    result = @scorer.score("C", @item)

    assert result[:is_correct]
  end

  test "handles whitespace in answer" do
    result = @scorer.score("  B  ", @item)

    assert result[:is_correct]
  end

  test "handles nil answer" do
    result = @scorer.score(nil, @item)

    assert_not result[:is_correct]
    assert_equal 0, result[:score]
  end
end
