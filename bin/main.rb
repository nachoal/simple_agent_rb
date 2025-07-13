#!/usr/bin/env ruby

require "dotenv"
Dotenv.load(File.join(__dir__, "..", ".env"))

require "http"
require "json"
require "colorize"

# Add lib to the load path
$LOAD_PATH.unshift(File.join(__dir__, "..", "lib"))

# Require your main classes
require "agent/agent"
require "llm_clients/openai_client"
require "llm_clients/deepseek_client"
require "llm_clients/perplexity_client"
require "llm_clients/moonshot_client"

# Only need to require the base Tool class and registry
require "tools/tool_registry"

puts "Welcome to the AI agent. Type 'exit' to quit".colorize(:blue)

# Initialize your agent with the desired LLM provider
agent = Agent.new(:moonshot, "kimi-k2-0711-preview")

loop do
  print "You: "
  question = gets.chomp
  break if question.downcase == "exit"

  puts agent.query(question)
end
