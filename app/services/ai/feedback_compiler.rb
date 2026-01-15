module Ai
  class FeedbackCompiler
    def compile(ai_payload, teacher_payload = {})
      merged = deep_merge(deep_dup(ai_payload || {}), teacher_payload || {})
      validator = Ai::FeedbackValidator.new
      errors = validator.validate(merged)
      [merged, errors]
    end

    private

    def deep_merge(target, source)
      source.each do |key, value|
        if target[key].is_a?(Hash) && value.is_a?(Hash)
          deep_merge(target[key], value)
        else
          target[key] = value
        end
      end
      target
    end

    def deep_dup(value)
      case value
      when Hash
        value.transform_values { |v| deep_dup(v) }
      when Array
        value.map { |v| deep_dup(v) }
      else
        value
      end
    end
  end
end
