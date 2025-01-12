class ChatBot
  OPENAI_API_URL = "https://api.openai.com/v1/chat/completions"
  attr_reader :messages

  def initialize(system = "")
    @system = system
    @messages = []
    @messages << { role: "system", content: system } if !@system.empty?
    @api_key = ENV["OPENAI_API_KEY"]
  end

  def call(message)
    @messages << { role: "user", content: message }
    result = execute
    @messages << { role: "assistant", content: result }
    result
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
          model: "gpt-4o",
          messages: @messages,
          max_tokens: 4000
        }
      )

    parsed_response = JSON.parse(response.body.to_s)
    # Uncomment to print token usage
    # puts parsed_response
    parsed_response.dig("choices", 0, "message", "content")
  end
end