require "http"
require "json"
require_relative "tool"

class GoogleSearchTool < Tool
  def initialize
    super("google_search")
    @api_key = ENV["GOOGLE_SEARCH_API_KEY"]
    @search_engine_id = ENV["GOOGLE_SEARCH_ENGINE_ID"]
  end

  def call(query)
    response = HTTP.get(
      "https://www.googleapis.com/customsearch/v1",
      params: {
        key: @api_key,
        cx: @search_engine_id,
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