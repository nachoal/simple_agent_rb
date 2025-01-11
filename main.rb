require "dotenv"
Dotenv.load(File.join(__dir__, ".env"))

require "http"
require "json"
require "colorize"

require_relative "llm_client"
require_relative "chat_bot"
require_relative "agent"

# Create an agent with OpenAI (default)
# agent = Agent.new

# Or use DeepSeek
agent = Agent.new(:deepseek)

# Or use Perplexity
# agent = Agent.new(:perplexity)

# Or specify a model
# agent = Agent.new(:openai, "gpt-4o")
# agent = Agent.new(:deepseek, "deepseek-chat")
# agent = Agent.new(:perplexity, "llama-3.1-sonar-small-128k-online")

puts "Welcome to the AI agent. Type 'exit' to quit".colorize(:blue)
while true
  print "You: "
  question = gets.chomp
  break if question.downcase == "exit"
  puts agent.query(question)
end
