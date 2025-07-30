#!/usr/bin/env ruby

require "dotenv"
Dotenv.load(File.join(__dir__, "..", ".env"))

require "colorize"
require "optparse"

# Add lib to the load path
$LOAD_PATH.unshift(File.join(__dir__, "..", "lib"))

# Require necessary classes
require "agent/configurable_agent"
require "tools/tool_registry"

# Parse command line options
options = { 
  verbose: false,
  personality: :therapist
}

OptionParser.new do |opts|
  opts.banner = "Usage: ruby configurable_example.rb [options]"
  
  opts.on("-v", "--verbose", "Enable verbose output") do
    options[:verbose] = true
  end
  
  opts.on("-p", "--personality PERSONALITY", 
          "Choose personality: therapist, teacher, writer, coder (default: therapist)") do |p|
    options[:personality] = p.to_sym
  end
  
  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

# Select the personality
system_prompt = case options[:personality]
when :therapist
  puts "Starting AI Therapist...".colorize(:magenta)
  AgentPersonalities::THERAPIST
when :teacher
  puts "Starting AI Teacher...".colorize(:blue)
  AgentPersonalities::TEACHER
when :writer
  puts "Starting Creative Writing Assistant...".colorize(:yellow)
  AgentPersonalities::CREATIVE_WRITER
when :coder
  puts "Starting Coding Mentor...".colorize(:green)
  AgentPersonalities::CODING_MENTOR
else
  puts "Unknown personality. Using therapist.".colorize(:red)
  AgentPersonalities::THERAPIST
end

puts "Type 'exit' to quit\n".colorize(:blue)

# Initialize agent with custom system prompt
agent = ConfigurableAgent.new(
  :moonshot, 
  "kimi-k2-0711-preview", 
  system_prompt: system_prompt,
  verbose: options[:verbose]
)

loop do
  print "You: ".colorize(:green)
  message = gets.chomp
  break if message.downcase == "exit"

  puts "\nAssistant: ".colorize(:cyan)
  puts agent.query(message)
  puts ""
end

puts "\nGoodbye! 👋".colorize(:blue)