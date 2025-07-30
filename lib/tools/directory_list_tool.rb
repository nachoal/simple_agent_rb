require_relative 'tool'
require 'json'

class DirectoryListTool < Tool
  extend ToolMetadata
  
  describe :call, "List files and directories. Input must be JSON with optional 'path' field. Example: {\"path\": \"directory\"} or {} for current directory."
  
  def initialize
    super("directory_list")
  end
  
  def call(input)
    begin
      params = JSON.parse(input)
      path = params["path"] || "."
    rescue JSON::ParserError => e
      return "Error parsing input: #{e.message}. Input must be JSON. Example: {\"path\": \"directory\"} or {}"
    end
    
    begin
      entries = Dir.glob(File.join(path, "**/*"), File::FNM_DOTMATCH)
        .reject { |f| f =~ /\/\.$|\/\.\.$/ }
        .map { |f| File.directory?(f) ? "#{f}/" : f }
        .sort
      
      JSON.generate(entries)
    rescue => e
      "Error listing directory: #{e.message}"
    end
  end
end