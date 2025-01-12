require "http"
require "json"
require_relative "tool"

class WikipediaTool < Tool
  def initialize
    super("wikipedia")
  end

  def call(query)
    response = HTTP.get(
      "https://en.wikipedia.org/w/api.php",
      params: {
        action: "query",
        list: "search",
        srsearch: query,
        format: "json"
      }
    )
    
    result = JSON.parse(response.body.to_s).dig("query", "search", 0, "snippet")
    result || "No results found"
  end
end 