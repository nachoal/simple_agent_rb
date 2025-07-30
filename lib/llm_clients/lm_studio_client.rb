require "http"
require "json"
require_relative "llm_client"

class LMStudioClient < LLMClient
  LM_STUDIO_BASE_URL = "http://localhost:1234/v1"
  LM_STUDIO_API_URL = "#{LM_STUDIO_BASE_URL}/chat/completions"
  LM_STUDIO_MODELS_URL = "#{LM_STUDIO_BASE_URL}/models"
  DEFAULT_MODEL = "local-model"

  def initialize(system = "", model = nil)
    super(system, model)
    @model ||= DEFAULT_MODEL
    puts "LM Studio client initialized for model: #{@model}"
  end

  private

  def execute
    payload = {
      model: @model,
      messages: @messages,
      max_tokens: 4000,
      temperature: 0.7
    }

    response = HTTP
      .headers(
        "Content-Type" => "application/json",
        "Authorization" => "Bearer lm-studio"
      )
      .post(
        LM_STUDIO_API_URL,
        json: payload
      )

    parsed_response = JSON.parse(response.body.to_s)

    if parsed_response["error"]
      raise "LM Studio API Error: #{parsed_response["error"]}"
    end

    parsed_response.dig("choices", 0, "message", "content")
  end

  public

  def chat_completion(messages:, tools: [], tool_choice: "auto")
    payload = {
      model: @model,
      messages: messages,
      max_tokens: 4000,
      temperature: 0.7
    }
    
    payload[:tools] = tools if tools.any?
    payload[:tool_choice] = tool_choice unless tool_choice == "auto"

    response = HTTP
      .headers(
        "Content-Type" => "application/json",
        "Authorization" => "Bearer lm-studio"
      )
      .post(
        LM_STUDIO_API_URL,
        json: payload
      )

    parsed_response = JSON.parse(response.body.to_s)

    if parsed_response["error"]
      raise "LM Studio API Error: #{parsed_response["error"]}"
    end

    parsed_response
  end

  # Class method to list available models
  def self.list_models
    begin
      response = HTTP
        .headers("Content-Type" => "application/json")
        .get(LM_STUDIO_MODELS_URL)

      parsed_response = JSON.parse(response.body.to_s)

      if parsed_response["error"]
        raise "LM Studio API Error: #{parsed_response["error"]}"
      end

      # Extract model IDs from the response
      models = parsed_response.dig("data") || []
      models.map { |model| model["id"] }
    rescue => e
      puts "Error connecting to LM Studio: #{e.message}".colorize(:red)
      puts "Make sure LM Studio is running on http://localhost:1234".colorize(:yellow)
      []
    end
  end
end
