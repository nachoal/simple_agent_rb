require "http"
require "json"
require_relative "llm_client"

class DeepSeekClient < LLMClient
  DEEPSEEK_API_URL = "https://api.deepseek.com/chat/completions"
  DEFAULT_MODEL = "deepseek-chat"

  def initialize(system = "", model = nil)
    super(system, model)
    @api_key = ENV["DEEPSEEK_API_KEY"]
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
        DEEPSEEK_API_URL,
        json: {
          model: @model,
          messages: @messages,
          stream: false
        }
      )

    begin
      parsed_response = JSON.parse(response.body.to_s)
      if parsed_response["error"]
        raise "DeepSeek API Error: #{parsed_response["error"]}"
      end
      parsed_response.dig("choices", 0, "message", "content")
    rescue JSON::ParserError => e
      puts "Failed to parse JSON response: #{response.body.to_s}"
      raise "DeepSeek API returned invalid JSON: #{e.message}"
    end
  end
end 