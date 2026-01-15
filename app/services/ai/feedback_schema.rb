module Ai
  class FeedbackSchema
    SCHEMA_PATH = Rails.root.join("config", "ai_schemas", "feedback_v1.json").freeze

    def self.required_keys
      schema.fetch("required_keys")
    end

    def self.types
      schema.fetch("types")
    end

    def self.schema
      @schema ||= JSON.parse(File.read(SCHEMA_PATH))
    end
  end
end
