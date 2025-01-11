class LLMClient
  def initialize(system = "", model = nil)
    @system = system
    @model = model
    @messages = []
    @messages << { role: "system", content: system } if !@system.empty?
  end

  def call(message)
    @messages << { role: "user", content: message }
    result = execute
    @messages << { role: "assistant", content: result }
    result
  end

  private

  def execute
    raise NotImplementedError, "Subclasses must implement execute"
  end
end

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

    # puts "Response status: #{response.status}"
    # puts "Response body: #{response.body.to_s}"
    
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