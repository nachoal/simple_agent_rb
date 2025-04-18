require "colorize"
require_relative "../tools/tool_registry"

class Agent
  ACTION_REGEX = /^Action: (\w+): (.*)$/

  PROMPT = <<~PROMPT
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

  def initialize(llm_provider = :openai, model = nil)
    @tool_registry = ToolRegistry.instance
    @llm_provider = llm_provider
    @model = model
  end

  def query(question, max_turns = 5)
    i = 0
    bot = create_llm_client
    next_prompt = question

    while i < max_turns
      i += 1
      result = bot.call(next_prompt)
      if result.nil?
        puts "[LLM returned no content]".colorize(:red)
        return
      end

      puts result.to_s.colorize(:yellow)

      actions = result.split("\n").map { |line| ACTION_REGEX.match(line) }.compact
      if actions.any?
        action, action_input = actions.first.captures
        tool = @tool_registry.fetch(action)
        
        puts " -- running #{action} #{action_input}".colorize(:green)
        observation = tool.call(action_input)
        puts "Observation: #{observation}".colorize(:green)
        next_prompt = "Observation: #{observation}"
      else
        return
      end
    end
  end

  private

  def create_llm_client
    case @llm_provider
    when :openai
      OpenAIClient.new(PROMPT, @model)
    when :deepseek
      DeepSeekClient.new(PROMPT, @model)
    when :perplexity
      PerplexityClient.new("", @model)
    else
      raise ArgumentError, "Unknown LLM provider: #{@llm_provider}"
    end
  end
end