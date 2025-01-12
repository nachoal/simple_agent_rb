require "http"
require "json"
require_relative "llm_client"

class PerplexityClient < LLMClient
  PERPLEXITY_API_URL = "https://api.perplexity.ai/chat/completions"
  DEFAULT_MODEL = "llama-3.1-sonar-huge-128k-online"

  def initialize(system = "", model = nil)
    @system = "Be precise and concise." # Override system prompt for Perplexity
    super(@system, model)
    @api_key = ENV["PERPLEXITY_API_KEY"]
    puts "Perplexity API Key: #{@api_key ? "present" : "missing"}"
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
        PERPLEXITY_API_URL,
        json: {
          model: @model,
          messages: @messages,
          temperature: 0.2,
          top_p: 0.9,
          search_domain_filter: ["perplexity.ai"],
          return_images: false,
          return_related_questions: false,
          search_recency_filter: "month",
          top_k: 0,
          stream: false,
          presence_penalty: 0,
          frequency_penalty: 1
        }
      )

    begin
      parsed_response = JSON.parse(response.body.to_s)
      if parsed_response["error"]
        raise "Perplexity API Error: #{parsed_response["error"]}"
      end
      parsed_response.dig("choices", 0, "message", "content")
    rescue JSON::ParserError => e
      puts "Failed to parse JSON response: #{response.body.to_s}"
      raise "Perplexity API returned invalid JSON: #{e.message}"
    end
  end
end 