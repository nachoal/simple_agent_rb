require "http"
require "json"
require_relative "llm_client"

class OpenAIClient < LLMClient
  OPENAI_API_URL = "https://api.openai.com/v1/chat/completions"
  DEFAULT_MODEL = "gpt-4"

  def initialize(system = "", model = nil)
    super(system, model)
    @api_key = ENV["OPENAI_API_KEY"]
    puts "OpenAI API Key: #{@api_key ? "present" : "missing"}"
    @model ||= DEFAULT_MODEL
  end

  private

  def execute
    # Build the request payload
    payload = {
      model: @model,
      messages: @messages
    }

    # Some models (like "o3") require :max_completion_tokens instead of :max_tokens
    if @model.to_s.start_with?("o3")
      payload[:max_completion_tokens] = 4000
    else
      payload[:max_tokens] = 4000
    end

    response = HTTP
      .headers(
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@api_key}"
      )
      .post(
        OPENAI_API_URL,
        json: payload
      )

    parsed_response = JSON.parse(response.body.to_s)

    if parsed_response["error"]
      raise "OpenAI API Error: #{parsed_response["error"]}"
    end

    parsed_response.dig("choices", 0, "message", "content")
  end
end 