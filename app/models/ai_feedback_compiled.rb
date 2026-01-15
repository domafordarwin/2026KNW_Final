class AiFeedbackCompiled < ApplicationRecord
  self.table_name = "ai_feedback_compiled"

  belongs_to :submission

  validate :compiled_json_schema

  private

  def compiled_json_schema
    validator = Ai::FeedbackValidator.new
    validation_errors = validator.validate(compiled_json || {})
    validation_errors.each { |error| errors.add(:compiled_json, error) }
  end
end
