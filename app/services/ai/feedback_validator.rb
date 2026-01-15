module Ai
  class FeedbackValidator
    def validate(payload)
      return ["payload must be a Hash"] unless payload.is_a?(Hash)

      errors = []
      required_keys = Ai::FeedbackSchema.required_keys
      types = Ai::FeedbackSchema.types

      required_keys.each do |key|
        errors << "missing #{key}" unless payload.key?(key)
      end

      types.each do |path, expected|
        value = fetch_path(payload, path)
        next if value.nil?
        next if type_matches?(value, expected)

        errors << "#{path} must be #{expected}"
      end

      errors
    end

    private

    def fetch_path(payload, path)
      keys = path.split(".")
      keys.reduce(payload) do |current, key|
        return nil unless current.is_a?(Hash)

        current[key]
      end
    end

    def type_matches?(value, expected)
      case expected
      when "string"
        value.is_a?(String)
      when "object"
        value.is_a?(Hash)
      when "array"
        value.is_a?(Array)
      else
        true
      end
    end
  end
end
