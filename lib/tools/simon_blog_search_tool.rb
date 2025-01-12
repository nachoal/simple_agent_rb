require "http"
require "json"
require_relative "tool"

class SimonBlogSearchTool < Tool
  def initialize
    super("simon_blog_search")
  end

  def call(query)
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
        q: query
      }
    )

    result = JSON.parse(response.body.to_s)
    result.first&.dig("text") || "No results found"
  end
end 