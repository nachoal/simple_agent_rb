#!/usr/bin/env ruby

require "dotenv"
Dotenv.load(File.join(__dir__, "..", ".env"))

require "http"
require "json"
require "colorize"
require "optparse"

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

# Parse command line options
options = { verbose: false }
OptionParser.new do |opts|
  opts.banner = "Usage: ruby main.rb [options]"
  
  opts.on("-v", "--verbose", "Enable verbose output (show tool execution details)") do
    options[:verbose] = true
  end
  
  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

puts "Welcome to the AI agent. Type 'exit' to quit".colorize(:blue)

# Initialize your agent with the desired LLM provider
agent = Agent.new(:moonshot, "kimi-k2-0711-preview", verbose: options[:verbose])

loop do
  print "You: ".colorize(:green)
  question = gets.chomp
  break if question.downcase == "exit"

  puts agent.query(question)
end
