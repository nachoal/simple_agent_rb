require "dotenv"
Dotenv.load(File.join(__dir__, ".env"))
require "http"
require "json"

require_relative "llm_client"
require_relative "chat_bot"
require_relative "agent"

# Create an agent with OpenAI (default)
# agent = Agent.new

# Or use DeepSeek
agent = Agent.new(:deepseek)

# Or specify a model
# agent = Agent.new(:openai, "gpt-4")
# agent = Agent.new(:deepseek, "deepseek-chat")

puts "Welcome to the AI agent. Type 'exit' to quit"
while true
  print "You: "
  question = gets.chomp
  break if question.downcase == "exit"
  puts agent.query(question)
end
