# Simple Agent Ruby - AI Agent Framework

## Overview

Simple Agent Ruby is a flexible framework for building AI agents with tool-calling capabilities. The framework supports multiple LLM providers (OpenAI, Moonshot, DeepSeek, Perplexity) and provides an extensible tool system that allows agents to interact with external systems.

## Architecture

### Core Components

1. **Agent (`lib/agent/agent.rb`)**
   - Main orchestrator that manages conversations with LLMs
   - Supports both ReAct-style prompting and OpenAI-style function calling
   - Handles tool execution and response formatting

2. **LLM Clients (`lib/llm_clients/`)**
   - Base class: `LLMClient` - defines the interface
   - Implementations: `OpenAIClient`, `MoonshotClient`, `DeepSeekClient`, `PerplexityClient`
   - Each client handles provider-specific API communication

3. **Tools (`lib/tools/`)**
   - Base class: `Tool` - all tools inherit from this
   - `ToolRegistry` - Singleton that auto-discovers and manages tools
   - `ToolMetadata` - Module for adding descriptions to tools
   - Tools are automatically loaded from the `lib/tools/` directory

### Available Tools

- **CalculateTool** - Evaluates mathematical expressions
- **WikipediaTool** - Searches Wikipedia for information
- **GoogleSearchTool** - Performs Google searches
- **FileReadTool** - Reads file contents
- **FileWriteTool** - Writes content to files
- **FileEditTool** - Edits files using string replacement
- **DirectoryListTool** - Lists files and directories

## Creating a New Agent

### Method 1: Custom System Prompt (Recommended)

The simplest way to create a new agent is to use a custom system prompt:

```ruby
#!/usr/bin/env ruby

require "dotenv"
Dotenv.load(File.join(__dir__, "..", ".env"))

require "colorize"
require "optparse"

# Add lib to the load path
$LOAD_PATH.unshift(File.join(__dir__, "..", "lib"))

# Require main classes
require "agent/agent"
require "llm_clients/moonshot_client"
require "tools/tool_registry"

# Define your custom system prompt
CUSTOM_PROMPT = <<~PROMPT
  You are a helpful coding assistant specialized in Ruby.
  Focus on writing clean, idiomatic Ruby code.
  Use the available tools when needed.
PROMPT

# Create the agent with custom prompt
agent = Agent.new(:moonshot, nil, verbose: false, system_prompt: CUSTOM_PROMPT)

# Run your agent
puts agent.query("Help me write a Ruby function to calculate fibonacci numbers")
```

### Method 2: Agent Subclass

For more complex behavior, create a subclass:

```ruby
class CodingAssistantAgent < Agent
  CODING_PROMPT = <<~PROMPT
    You are an expert coding assistant.
    Always write clean, well-documented code.
    Test your solutions when possible.
  PROMPT

  def create_llm_client(provider, model, verbose)
    # Use your custom prompt
    system_prompt = CODING_PROMPT
    
    case provider
    when :openai
      OpenAIClient.new(system_prompt, model || 'gpt-4')
    when :moonshot
      MoonshotClient.new(system_prompt, model || 'kimi-k2-0711-preview')
    # ... other providers
    end
  end
  
  # Override other methods if needed
  def run_interactive
    puts "Welcome to Coding Assistant!"
    super # Call parent implementation
  end
end
```

## Creating a New Tool

Tools are automatically discovered and loaded. To create a new tool:

1. Create a file in `lib/tools/` (e.g., `lib/tools/weather_tool.rb`)
2. Extend the `Tool` base class
3. Use `ToolMetadata` to describe the tool
4. Implement the `call` method

```ruby
require_relative "tool"
require_relative "tool_metadata"
require "json"

class WeatherTool < Tool
  extend ToolMetadata
  
  # IMPORTANT: Use 'extend' not 'include' for ToolMetadata
  # The description helps the LLM understand when to use this tool
  describe :call, "Get current weather for a given city. Returns temperature and conditions."
  
  def initialize
    super("weather")  # Tool name used in prompts
  end
  
  def call(input)
    # Parse the input - tools receive JSON strings
    begin
      params = JSON.parse(input)
      city = params["city"]
      
      return "Error: city parameter is required" unless city
    rescue JSON::ParserError => e
      return "Error parsing input: #{e.message}. Input must be JSON like: {\"city\": \"London\"}"
    end
    
    begin
      # Your tool implementation here
      # This is a mock response - replace with actual API call
      temperature = rand(0..35)
      conditions = ["sunny", "cloudy", "rainy"].sample
      
      "Weather in #{city}: #{temperature}°C, #{conditions}"
    rescue => e
      "Error fetching weather: #{e.message}"
    end
  end
end
```

### Tool Input Format

**IMPORTANT**: The agent framework passes tool inputs as a single string through the "input" parameter. Your tool should expect JSON-formatted strings.

For example, if your tool needs multiple parameters:
```json
{"path": "file.txt", "content": "Hello World"}
```

The LLM will pass this entire JSON as a string to your tool's `call` method.

### Tool Best Practices

1. **Input Handling**
   - Tools receive JSON strings as input
   - Always wrap JSON parsing in begin/rescue blocks
   - Always parse and validate inputs
   - Return clear error messages with examples of correct format

2. **Error Handling**
   - Catch exceptions and return user-friendly error messages
   - Never let exceptions bubble up to the agent

3. **Descriptions**
   - Write clear, concise descriptions
   - Mention what parameters are expected
   - Explain what the tool returns

4. **Naming**
   - Use descriptive names ending with "Tool"
   - Keep tool names consistent with their function

## Running Agents

### Interactive Mode

Most agents support interactive mode for conversations:

```ruby
# In your agent script
agent = Agent.new(:moonshot, nil, verbose: false)

loop do
  print "You: "
  user_input = gets.chomp
  break if user_input.downcase == 'exit'
  
  puts "Agent: #{agent.query(user_input)}"
end
```

### Single Query Mode

For one-off queries:

```ruby
agent = Agent.new(:openai, 'gpt-4')
response = agent.query("What is the capital of France?")
puts response
```

### Verbose Mode

Enable verbose mode to see tool execution details:

```ruby
agent = Agent.new(:moonshot, nil, verbose: true)
```

## Example: Therapist Agent

Here's the complete therapist agent implementation as an example:

```ruby
#!/usr/bin/env ruby

require "dotenv"
Dotenv.load(File.join(__dir__, "..", ".env"))

require "colorize"
require "optparse"

$LOAD_PATH.unshift(File.join(__dir__, "..", "lib"))

require "agent/agent"
require "llm_clients/moonshot_client"
require "tools/tool_registry"

THERAPIST_PROMPT = <<~PROMPT
  You are a compassionate and professional AI therapist.
  
  Key principles:
  - Practice active listening and reflect back what the client shares
  - Show empathy and validate emotions without judgment
  - Ask open-ended questions to encourage self-reflection
  - Maintain professional boundaries and ethics
  - Never diagnose medical conditions or prescribe medications
  
  You have access to file tools to:
  - Take session notes in the 'sessions' directory
  - Read previous session notes for continuity
  - Track progress over time
PROMPT

# Parse command line options
options = { verbose: false, provider: :moonshot }
OptionParser.new do |opts|
  opts.banner = "Usage: ruby therapist.rb [options]"
  
  opts.on("-v", "--verbose", "Enable verbose mode") do
    options[:verbose] = true
  end
  
  opts.on("-p", "--provider PROVIDER", "LLM provider") do |provider|
    options[:provider] = provider.to_sym
  end
end.parse!

# Create and run the agent
agent = Agent.new(options[:provider], nil, 
                  verbose: options[:verbose], 
                  system_prompt: THERAPIST_PROMPT)

puts "Welcome to your therapy session..."

loop do
  print "\nYou: "
  user_input = gets.chomp
  break if user_input.downcase == 'exit'
  
  puts "\nTherapist: "
  puts agent.query(user_input)
end
```

## Environment Variables

Required environment variables for different providers:

- **OpenAI**: `OPENAI_API_KEY`
- **Moonshot**: `MOONSHOT_API_KEY`
- **DeepSeek**: `DEEPSEEK_API_KEY`
- **Perplexity**: `PERPLEXITY_API_KEY`
- **Google Search Tool**: `GOOGLE_API_KEY`, `GOOGLE_CX`

## Troubleshooting

### Common Issues

1. **"wrong number of arguments" error**
   - Check that tools use `extend ToolMetadata` (not `include`)
   - Ensure `describe :call, "description"` format is correct

2. **Tool not found**
   - Verify the tool file is in `lib/tools/`
   - Check that the tool class name matches the file name
   - Ensure the tool calls `super("tool_name")` in initialize

3. **LLM provider errors**
   - Verify API keys are set in environment
   - Check that the provider symbol matches exactly (`:openai`, not `"openai"`)

4. **System prompt not working**
   - Make sure to pass `system_prompt:` as a keyword argument
   - Verify the Agent class has been updated to support custom prompts

5. **Agent uses tools but doesn't respond**
   - Make sure to capture and print the query response: `puts agent.query(input)`
   - Increase max_turns if needed: `agent.query(input, 10)`
   - Add instructions in system prompt to respond after tool use
   - Use verbose mode (`-v`) to debug what's happening

6. **Tool input errors (e.g., "unexpected character")**
   - Tools expect JSON input: `{"param": "value"}`
   - Include JSON examples in tool descriptions
   - Add JSON examples to system prompt for file tools

## Development Guidelines

1. **Keep agents simple** - Let the system prompt do the work
2. **Tools should be focused** - Each tool does one thing well
3. **Use existing patterns** - Follow the conventions in existing code
4. **Test your tools** - Ensure they handle errors gracefully
5. **Document behavior** - Use clear descriptions for tools and agents

## Directory Structure

```
simple_agent_rb/
├── bin/
│   ├── main.rb          # Example general-purpose agent
│   └── therapist.rb     # Example specialized agent
├── lib/
│   ├── agent/
│   │   └── agent.rb     # Main Agent class
│   ├── llm_clients/
│   │   ├── llm_client.rb      # Base class
│   │   ├── openai_client.rb   # OpenAI implementation
│   │   └── ...                # Other providers
│   └── tools/
│       ├── tool.rb            # Base Tool class
│       ├── tool_registry.rb   # Auto-discovery system
│       ├── tool_metadata.rb   # Description system
│       └── ...                # Individual tools
└── CLAUDE.md            # This documentation
```

## Quick Start Checklist

To create a new agent:

1. ✓ Copy the therapist.rb example
2. ✓ Change the PROMPT constant to your needs
3. ✓ Update welcome/goodbye messages
4. ✓ Set appropriate command-line options
5. ✓ Test with `ruby bin/your_agent.rb`

To create a new tool:

1. ✓ Create file in `lib/tools/your_tool.rb`
2. ✓ Extend Tool class
3. ✓ Use `extend ToolMetadata` (not include!)
4. ✓ Add `describe :call, "description"`
5. ✓ Implement `call(input)` method
6. ✓ Test that the tool appears in agent startup

Remember: The framework handles all the complexity. Focus on your agent's personality and your tools' functionality!