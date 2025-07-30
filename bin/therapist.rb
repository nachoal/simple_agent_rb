#!/usr/bin/env ruby

require "dotenv"
Dotenv.load(File.join(__dir__, "..", ".env"))

require "colorize"
require "optparse"

# Add lib to the load path
$LOAD_PATH.unshift(File.join(__dir__, "..", "lib"))

# Require main classes
require "agent/agent"
require "llm_clients/openai_client"
require "llm_clients/deepseek_client"
require "llm_clients/perplexity_client"
require "llm_clients/moonshot_client"
require "llm_clients/lm_studio_client"
require "input/input_handler"
require "tools/tool_registry"

THERAPIST_PROMPT = <<~PROMPT
  You are a compassionate and professional AI therapist. Your role is to provide emotional support, 
  active listening, and thoughtful guidance while maintaining appropriate therapeutic boundaries.

  Key principles:
  - Practice active listening and reflect back what the client shares
  - Show empathy and validate emotions without judgment
  - Ask open-ended questions to encourage self-reflection
  - Maintain professional boundaries and ethics
  - Never diagnose medical conditions or prescribe medications
  - Encourage professional help when appropriate
  - Keep sessions confidential and create a safe space

  You have access to file tools to:
  - Take session notes in the 'sessions' directory
  - Read previous session notes for continuity
  - Create summaries or insights files
  - Track progress over time
  
  When using file tools, always pass JSON formatted input:
  - file_write: {"path": "sessions/note.md", "content": "Session content here"}
  - file_read: {"path": "sessions/note.md"}
  - file_edit: {"path": "file.md", "old_str": "old text", "new_str": "new text"}
  - directory_list: {"path": "sessions"}

  Session Management:
  - At the start, check if there are previous sessions to provide continuity
  - During the session, you may take notes using the file tools
  - At the end, save a summary if the client wishes

  IMPORTANT: After using any file tools, always provide a conversational response to the client. 
  Don't just use tools silently - acknowledge what you've done and continue the therapeutic conversation.

  Remember: You are here to support, not to fix. Guide clients toward their own insights and solutions.
PROMPT

# Parse command line options
options = { verbose: false, provider: :moonshot }
OptionParser.new do |opts|
  opts.banner = "Usage: ruby therapist.rb [options]"
  
  opts.on("-v", "--verbose", "Enable verbose mode") do
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
  
  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
end.parse!

# Welcome message
unless options[:model_selected]
  puts "\n🌟 Welcome to your therapy session. This is a safe, confidential space where you can share whatever is on your mind.\n".colorize(:green)
  puts "I'm here to listen and support you. You can end our session at any time by typing 'exit' or 'quit'.\n".colorize(:light_blue)
  puts "=" * 80
else
  puts "\n🌟 Starting therapy session with selected model.\n".colorize(:green)
  puts "=" * 80
end

# Create and run the therapist agent
begin
  agent = Agent.new(options[:provider], options[:model], verbose: options[:verbose], system_prompt: THERAPIST_PROMPT)
  
  # Initialize the enhanced input handler with a different history file for therapy sessions
  input_handler = InputHandler.new(history_file: File.join(Dir.home, '.simple_agent_therapy_history'))
  
  loop do
    user_input = input_handler.read_input(prompt_text: "💭 You: ", agent_status: "Listening")
    
    break if user_input.nil? || user_input.downcase == 'exit' || user_input.downcase == 'quit'
    
    puts "\n💚 Therapist: ".colorize(:green)
    response = agent.query(user_input, 10)  # Allow more iterations for complex tool use
    puts response if response
  end
  
  # End of session
  puts "\n" + "=" * 80
  puts "\n🌟 Thank you for sharing with me today. Remember, taking time for your mental health is a sign of strength.\n".colorize(:green)
  puts "Take care of yourself. I'm here whenever you need to talk. 💚\n".colorize(:light_blue)
  
rescue => e
  puts "Error: #{e.message}".colorize(:red)
  puts e.backtrace if options[:verbose]
  exit 1
end