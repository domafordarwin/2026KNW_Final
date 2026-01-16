require "test_helper"

class Ai::FeedbackValidatorTest < ActiveSupport::TestCase
  setup do
    @validator = Ai::FeedbackValidator.new
  end

  test "valid payload passes validation" do
    payload = {
      "executive_summary" => "Test summary",
      "subskill_synthesis" => { "reading" => {} },
      "item_analysis" => [],
      "integrated" => { "domain_guidance" => {}, "parent_summary" => "Test" },
      "trait_explanation" => "Test explanation"
    }

    errors = @validator.validate(payload)
    assert_empty errors
  end

  test "missing required keys reports errors" do
    payload = { "executive_summary" => "Test" }

    errors = @validator.validate(payload)
    assert errors.any? { |e| e.include?("missing") }
  end

  test "wrong types report errors" do
    payload = {
      "executive_summary" => 123, # Should be string
      "subskill_synthesis" => {},
      "item_analysis" => [],
      "integrated" => {},
      "trait_explanation" => "Test"
    }

    errors = @validator.validate(payload)
    assert errors.any? { |e| e.include?("must be") }
  end

  test "non-hash payload reports error" do
    errors = @validator.validate("not a hash")
    assert_includes errors, "payload must be a Hash"
  end
end
