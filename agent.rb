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
    @known_actions = {
      "wikipedia" => method(:wikipedia),
      "calculate" => method(:calculate),
      "simon_blog_search" => method(:simon_blog_search)
    }

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
      puts result

      actions = result.split("\n").map { |line| ACTION_REGEX.match(line) }.compact
      if actions.any?
        action, action_input = actions.first.captures
        raise "Unknown action: #{action}: #{action_input}" unless @known_actions.key?(action)

        puts " -- running #{action} #{action_input}"
        observation = @known_actions[action].call(action_input)
        puts "Observation: #{observation}"
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
    else
      raise ArgumentError, "Unknown LLM provider: #{@llm_provider}"
    end
  end

  def wikipedia(q)
    response = HTTP.get(
      "https://en.wikipedia.org/w/api.php",
      params: {
        action: "query",
        list: "search",
        srsearch: q,
        format: "json"
      }
    )
    JSON.parse(response.body.to_s).dig("query", "search", 0, "snippet")
  end

  def simon_blog_search(q)
    sql = <<~SQL
      select
        blog_entry.title || ': ' || substr(html_strip_tags(blog_entry.body), 0, 1000) as text,
        blog_entry.created
      from
        blog_entry join blog_entry_fts on blog_entry.rowid = blog_entry_fts.rowid
      where
        blog_entry_fts match escape_fts(:q)
      order by
        blog_entry_fts.rank
      limit
        1
    SQL

    response = HTTP.get(
      "https://datasette.simonwillison.net/simonwillisonblog.json",
      params: {
        sql: sql,
        "_shape": "array",
        q: q
      }
    )
    JSON.parse(response.body.to_s).first["text"]
  end

  def calculate(expression)
    eval(expression)
  end
end