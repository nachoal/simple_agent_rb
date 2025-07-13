require "http"
require "json"
require_relative "llm_client"

class MoonshotClient < LLMClient
  MOONSHOT_API_URL = "https://api.moonshot.ai/v1/chat/completions"
  DEFAULT_MODEL = "moonshot-v1-8k"

  def initialize(system = "", model = nil)
    super(system, model)
    @api_key = ENV["MOONSHOT_API_KEY"]
    puts "Moonshot API Key: #{@api_key ? "present" : "missing"}"
    @model ||= DEFAULT_MODEL
  end

  private

  def execute
    # Build the request payload
    payload = {
      model: @model,
      messages: @messages,
      temperature: 0.3
    }

    response = HTTP
      .headers(
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@api_key}"
      )
      .post(
        MOONSHOT_API_URL,
        json: payload
      )

    parsed_response = JSON.parse(response.body.to_s)

    if parsed_response["error"]
      raise "Moonshot API Error: #{parsed_response["error"]}"
    end

    parsed_response.dig("choices", 0, "message", "content")
  end

  public

  def chat_completion(messages:, tools: [], tool_choice: "auto")
    payload = {
      model: @model,
      messages: messages,
      temperature: 0.3
    }
    payload[:tools] = tools if tools.any?
    payload[:tool_choice] = tool_choice unless tool_choice == "auto"

    response = HTTP
      .headers(
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@api_key}"
      )
      .post(
        MOONSHOT_API_URL,
        json: payload
      )

    parsed_response = JSON.parse(response.body.to_s)

    if parsed_response["error"]
      raise "Moonshot API Error: #{parsed_response["error"]}"
    end

    parsed_response
  end
end 