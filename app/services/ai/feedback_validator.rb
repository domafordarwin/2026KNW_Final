module Ai
  class FeedbackValidator
    def validate(payload)
      return ["payload must be a Hash"] unless payload.is_a?(Hash)

      errors = []
      Ai::FeedbackSchema.required_keys.each do |key|
        errors << "missing #{key}" unless payload.key?(key)
      end

      errors << "executive_summary must be String" unless payload["executive_summary"].is_a?(String)
      errors << "subskill_synthesis must be Hash" unless payload["subskill_synthesis"].is_a?(Hash)
      errors << "item_analysis must be Array" unless payload["item_analysis"].is_a?(Array)
      errors << "integrated must be Hash" unless payload["integrated"].is_a?(Hash)

      if payload["integrated"].is_a?(Hash) && payload["integrated"].key?("domain_guidance")
        unless payload["integrated"]["domain_guidance"].is_a?(Hash)
          errors << "integrated.domain_guidance must be Hash"
        end
      end

      errors
    end
  end
end
