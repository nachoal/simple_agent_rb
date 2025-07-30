require_relative 'tool'
require 'json'

class FileReadTool < Tool
  extend ToolMetadata
  
  describe :call, "Read the contents of a file. Input must be JSON with 'path' field. Example: {\"path\": \"file.txt\"}"
  
  def initialize
    super("file_read")
  end
  
  def call(input)
    begin
      params = JSON.parse(input)
      path = params["path"]
      
      return "Error: path parameter is required. Input must be JSON like: {\"path\": \"file.txt\"}" unless path
    rescue JSON::ParserError => e
      return "Error parsing input: #{e.message}. Input must be JSON with 'path' field. Example: {\"path\": \"file.txt\"}"
    end
    
    begin
      content = File.read(path)
      content
    rescue Errno::ENOENT
      "Error: File not found: #{path}"
    rescue => e
      "Error reading file: #{e.message}"
    end
  end
end