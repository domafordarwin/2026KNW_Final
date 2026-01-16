module Ai
  class OpenaiClient
    MAX_RETRIES = 3
    TIMEOUT = 30

    def initialize
      @api_key = ENV["OPENAI_API_KEY"]
      @model = ENV.fetch("OPENAI_MODEL", "gpt-4o-mini")
    end

    def chat(messages, schema: nil)
      retries = 0

      begin
        response = make_request(messages, schema)
        parse_response(response, schema)
      rescue StandardError => e
        retries += 1
        if retries < MAX_RETRIES
          sleep(2 ** retries)
          retry
        end
        raise e
      end
    end

    private

    def make_request(messages, schema)
      uri = URI("https://api.openai.com/v1/chat/completions")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = TIMEOUT

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@api_key}"
      request["Content-Type"] = "application/json"

      body = {
        model: @model,
        messages: messages,
        temperature: 0.7,
        max_tokens: 2000
      }

      body[:response_format] = { type: "json_object" } if schema

      request.body = body.to_json
      http.request(request)
    end

    def parse_response(response, schema)
      unless response.is_a?(Net::HTTPSuccess)
        raise "OpenAI API error: #{response.code} - #{response.body}"
      end

      data = JSON.parse(response.body)
      content = data.dig("choices", 0, "message", "content")

      if schema
        JSON.parse(content)
      else
        content
      end
    end
  end
end
