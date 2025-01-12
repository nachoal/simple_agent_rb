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
    response = HTTP
      .headers(
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@api_key}"
      )
      .post(
        OPENAI_API_URL,
        json: {
          model: @model,
          messages: @messages,
          max_tokens: 4000
        }
      )

    parsed_response = JSON.parse(response.body.to_s)
    parsed_response.dig("choices", 0, "message", "content")
  end
end 