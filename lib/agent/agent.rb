require "colorize"
require "json"
require "tty-markdown"
require_relative "../tools/tool_registry"

class Agent
  ACTION_REGEX = /^Action: (\w+): (.*)$/

  PROMPT_REACT = <<~PROMPT
    You run in a loop of Thought, Action, PAUSE, Observation.
    At the end of the loop you output an Answer
    Use Thought to describe your thoughts about the question you have been asked.
    Use Action to run one of the actions available to you - then return PAUSE.
    Observation will be the result of running those actions.

    Your available actions are:

    calculate:
    e.g. calculate: 4 * 7 / 3
    Runs a calculation and returns the number - uses Ruby so be sure to use floating point syntax if necessary

    wikipedia:
    e.g. wikipedia: Django
    Returns a summary from searching Wikipedia

    google_search:
    e.g. google_search: Ruby on Rails tutorials
    Returns the top 10 results from Google Custom Search API, each with a title, URL, and description

    Always look things up on Wikipedia if you have the opportunity to do so.

    Example session:

    Question: What is the capital of France?
    Thought: I should look up France on Wikipedia
    Action: wikipedia: France
    PAUSE

    You will be called again with this:

    Observation: France is a country. The capital is Paris.

    You then output:

    Answer: The capital of France is Paris
  PROMPT

  # System prompt tailored for OpenAI function‑calling agent
  PROMPT_TOOLCALL = <<~PROMPT
    You are an AI assistant that can leverage external tools to answer the user.
    You have access to a set of tools defined separately in the request. When useful, call them.
    When you don't call a tool use markdown to format your response.

    Guidelines:
    1. If the answer can be given directly, do so.
    2. If you need to look up information, call the relevant tool. Do NOT fabricate tool calls.
    3. A tool call response will be provided with role "tool". You can combine multiple tool calls if helpful.
    4. After you have enough information, respond to the user with a clear final answer.

    When calling a tool, respond with **ONLY** a JSON payload following this format:
    {
      "name": "tool_name",
      "arguments": { ... }
    }
    Do **not** add any other keys. Do **not** think about the JSON structure—just output it.
  PROMPT

  def initialize(llm_provider = :openai, model = nil, verbose: false)
    @tool_registry = ToolRegistry.instance
    @llm_provider = llm_provider
    @model = model
    @verbose = verbose
    @bot = create_llm_client
    
    # Log the chosen provider and model
    model_info = @model ? @model : "default"
    puts "Using #{@llm_provider} with model: #{model_info}".colorize(:blue)
    
    # Display loaded tools
    tools = @tool_registry.tools
    puts "\nLoaded #{tools.size} tools:".colorize(:cyan)
    tools.each do |name, tool|
      description = tool.class.description_for(:call) || "No description provided"
      puts "  • #{name}: #{description}".colorize(:light_blue)
    end
    puts ""
  end

  # Helper methods for formatted output
  def log_iteration(current, max)
    puts "🔄 Agent iteration #{current}/#{max}".colorize(:cyan)
  end

  def log_tool_calls_start(count)
    puts "  ↘️  Agent making #{count} tool call(s)".colorize(:light_cyan)
  end

  def log_tool_call(tool_name)
    puts "    📞 Calling tool: #{tool_name}".colorize(:light_cyan)
  end

  def log_no_tools
    puts "  ↻  Agent responded without tool calls - continuing loop".colorize(:light_cyan)
  end

  def log_completion
    puts "✅ Task completion tool called - exiting loop".colorize(:green)
  end

  def query(question, max_turns = 5)
    i = 0
    bot = @bot
    next_prompt = question
    tool_choice = "auto"

    while i < max_turns
      i += 1
      
      # Show iteration number in non-verbose mode
      log_iteration(i, max_turns) unless @verbose

      if @llm_provider == :openai || @llm_provider == :moonshot
        # Use OpenAI-compatible function calling
        bot.messages << { role: "user", content: next_prompt } if next_prompt

        response = bot.chat_completion(messages: bot.messages, tools: @tool_registry.tool_schemas, tool_choice: tool_choice)
        assistant_message = response.dig("choices", 0, "message")

        if assistant_message.nil?
          puts "[LLM returned no content]".colorize(:red)
          return
        end

        # Append assistant message to history immediately
        bot.messages << assistant_message

        # Handle moonshot's different tool call format
        if @llm_provider == :moonshot && !assistant_message["tool_calls"] && assistant_message["content"]
          begin
            content = assistant_message["content"].strip
            tool_calls = []
            
            # Try to parse as single JSON object first
            begin
              parsed_content = JSON.parse(content)
              if parsed_content["name"] && parsed_content["arguments"]
                tool_calls << {
                  "id" => parsed_content["id"] || "call_#{Time.now.to_i}_#{rand(1000)}",
                  "type" => "function",
                  "function" => {
                    "name" => parsed_content["name"],
                    "arguments" => parsed_content["arguments"].to_json
                  }
                }
              end
            rescue JSON::ParserError
              # If single JSON parsing fails, try to extract multiple JSON objects
              # Look for patterns like {"name": "tool_name", "arguments": {...}}
              json_pattern = /\{"name":\s*"([^"]+)",\s*"arguments":\s*\{[^}]*\}(?:,\s*"id":\s*"[^"]+")?\}/
              content.scan(json_pattern) do |match|
                begin
                  json_str = $&  # The full matched string
                  parsed = JSON.parse(json_str)
                  if parsed["name"] && parsed["arguments"]
                    tool_calls << {
                      "id" => parsed["id"] || "call_#{Time.now.to_i}_#{rand(1000)}",
                      "type" => "function",
                      "function" => {
                        "name" => parsed["name"],
                        "arguments" => parsed["arguments"].to_json
                      }
                    }
                  end
                rescue JSON::ParserError
                  # Skip invalid JSON
                end
              end
            end
            
            if tool_calls.any?
              assistant_message["tool_calls"] = tool_calls
              assistant_message["content"] = nil
            end
          rescue => e
            # If all parsing fails, continue as normal response
            puts "Failed to parse moonshot tool calls: #{e.message}".colorize(:yellow)
          end
        end

        # If the model decided to call one or more functions
        if assistant_message["tool_calls"]
          # Show tool calls count in non-verbose mode
          log_tool_calls_start(assistant_message["tool_calls"].length) unless @verbose
          
          assistant_message["tool_calls"].each do |tool_call|
            tool_name = tool_call.dig("function", "name")
            raw_args  = tool_call.dig("function", "arguments")
            args      = JSON.parse(raw_args) rescue { "input" => raw_args }
            tool_input = args["input"]

            tool = @tool_registry.fetch(tool_name)

            if @verbose
              puts " -- running #{tool_name} #{tool_input}".colorize(:green)
            else
              log_tool_call(tool_name)
            end
            
            observation = tool.call(tool_input)
            
            if @verbose
              puts "Observation: #{observation}".colorize(:green)
            end

            # Append the result for this specific tool call
            bot.messages << {
              role: "tool",
              tool_call_id: tool_call["id"],
              content: observation.to_s
            }
          end

          # After providing all tool responses, ask the LLM to continue.
          next_prompt = nil # No new user message
          tool_choice = "none" # Encourage the model to answer without additional tool calls
          next
        else
          # No tool calls -> final answer
          log_no_tools unless @verbose
          return format_markdown(assistant_message["content"])
        end

      else
        # Original non-OpenAI flow
        result = bot.call(next_prompt)
        if result.nil?
          puts "[LLM returned no content]".colorize(:red)
          return
        end

        actions = result.split("\n").map { |line| ACTION_REGEX.match(line) }.compact
        puts format_markdown(result) if actions.any?

        if actions.any?
          # Show tool calls count in non-verbose mode
          log_tool_calls_start(1) unless @verbose
          
          action, action_input = actions.first.captures
          tool = @tool_registry.fetch(action)
          
          if @verbose
            puts " -- running #{action} #{action_input}".colorize(:green)
          else
            log_tool_call(action)
          end
          
          observation = tool.call(action_input)
          
          if @verbose
            puts "Observation: #{observation}".colorize(:green)
          end
          
          next_prompt = "Observation: #{observation}"
        else
          # No action lines, final answer
          log_no_tools unless @verbose
          puts format_markdown(result)
          return result
        end
      end

      # reset tool_choice for non-OpenAI flows
      tool_choice = "auto"
    end
  end

  private

  def format_markdown(text)
    return text if text.nil? || text.empty?
    
    # Only format if it looks like it contains markdown
    if text.match?(/[*_#`\[\]()]/)
      TTY::Markdown.parse(text, 
        width: 120,
        theme: {
          em: :yellow,
          strong: [:cyan, :bold],
          header: [:magenta, :bold],
          link: :blue,
          code: :green,
          quote: :italic,
          hr: :yellow,
          list: :cyan,
          table: :magenta
        }
      )
    else
      text
    end
  rescue => e
    # Fallback to plain text if parsing fails
    puts "Markdown parsing failed: #{e.message}".colorize(:red) if @verbose
    text
  end

  def create_llm_client
    case @llm_provider
    when :openai
      OpenAIClient.new(PROMPT_TOOLCALL, @model)
    when :deepseek
      DeepSeekClient.new(PROMPT_REACT, @model)
    when :perplexity
      PerplexityClient.new("", @model)
    when :moonshot
      MoonshotClient.new(PROMPT_TOOLCALL, @model)
    else
      raise ArgumentError, "Unknown LLM provider: #{@llm_provider}"
    end
  end
end