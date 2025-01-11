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
    @known_actions = {
      "wikipedia" => method(:wikipedia),
      "calculate" => method(:calculate),
      "simon_blog_search" => method(:simon_blog_search),
      "google_search" => method(:google_search)
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
      puts result.colorize(:yellow)

      actions = result.split("\n").map { |line| ACTION_REGEX.match(line) }.compact
      if actions.any?
        action, action_input = actions.first.captures
        raise "Unknown action: #{action}: #{action_input}" unless @known_actions.key?(action)

        puts " -- running #{action} #{action_input}".colorize(:green)
        observation = @known_actions[action].call(action_input)
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

  def google_search(query)
    api_key = ENV["GOOGLE_SEARCH_API_KEY"]
    search_engine_id = ENV["GOOGLE_SEARCH_ENGINE_ID"]

    response = HTTP.get(
      "https://www.googleapis.com/customsearch/v1",
      params: {
        key: api_key,
        cx: search_engine_id,
        q: query,
        num: 10
      }
    )

    result = JSON.parse(response.body.to_s)
    return "No results found" unless result["items"]&.any?

    total_results = result.dig("searchInformation", "formattedTotalResults")
    search_time = result.dig("searchInformation", "formattedSearchTime")
    
    output = ["Found #{total_results} results in #{search_time} seconds\n"]

    result["items"].first(10).map.with_index(1) do |item, index|
      output << "#{index}. #{item["title"]}"
      output << "URL: #{item["link"]}"
      output << "Description: #{item["snippet"]}"
      
      # Add additional useful information if available
      output << "File Format: #{item["fileFormat"]}" if item["fileFormat"]
      output << "Site Name: #{item["displayLink"]}" if item["displayLink"]
      
      if item["pagemap"]&.dig("metatags", 0)
        metatags = item["pagemap"]["metatags"][0]
        output << "Description (meta): #{metatags["og:description"]}" if metatags["og:description"]
      end
      
      output << "" # Empty line for separation
    end

    output.join("\n")
  end
end