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
require "llm_clients/lm_studio_client"
require "input/input_handler"

# Only need to require the base Tool class and registry
require "tools/tool_registry"

# Parse command line options
options = { verbose: false, provider: :moonshot, model: "kimi-k2-0711-preview" }
OptionParser.new do |opts|
  opts.banner = "Usage: ruby main.rb [options]"
  
  opts.on("-v", "--verbose", "Enable verbose output (show tool execution details)") do
    options[:verbose] = true
  end

  opts.on("-p", "--provider PROVIDER", "LLM provider (openai, deepseek, perplexity, moonshot, lmstudio)") do |provider|
    options[:provider] = provider.to_sym
  end
  
  opts.on("-m", "--model MODEL", "Model name") do |model|
    options[:model] = model
  end

  opts.on("--list-lm-studio-models", "List available models from LM Studio") do
    puts "\n🔍 Fetching available models from LM Studio...".colorize(:cyan)
    models = LMStudioClient.list_models
    
    if models.empty?
      puts "No models found. Make sure LM Studio is running with loaded models.".colorize(:red)
      exit 1
    end
    
    puts "\n📋 Available LM Studio models:".colorize(:green)
    models.each_with_index do |model, index|
      puts "  #{index + 1}. #{model}".colorize(:light_blue)
    end
    
    print "\n🎯 Enter the number of the model you want to use: ".colorize(:yellow)
    choice = gets.chomp.to_i
    
    if choice < 1 || choice > models.length
      puts "Invalid choice. Exiting.".colorize(:red)
      exit 1
    end
    
    selected_model = models[choice - 1]
    puts "Selected model: #{selected_model}".colorize(:green)
    
    options[:provider] = :lmstudio
    options[:model] = selected_model
    options[:model_selected] = true
  end
  
  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

puts "Welcome to the AI agent. Type 'exit' or '/help' for help".colorize(:blue)

# Initialize your agent with the desired LLM provider
agent = Agent.new(options[:provider], options[:model], verbose: options[:verbose])

# Initialize the enhanced input handler
input_handler = InputHandler.new

loop do
  question = input_handler.read_input(prompt_text: "You: ", agent_status: "Ready")
  break if question.nil? || question.downcase == "exit"

  puts agent.query(question)
end
