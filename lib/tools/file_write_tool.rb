require_relative 'tool'
require 'json'
require 'fileutils'

class FileWriteTool < Tool
  extend ToolMetadata
  
  describe :call, "Write content to a file, creating it if it doesn't exist. This overwrites the entire file content. Input should be a JSON string with 'path' and 'content' fields."
  
  def initialize
    super("file_write")
  end
  
  def call(input)
    begin
      # Handle both JSON input and direct string input for backward compatibility
      if input.start_with?('{') && input.end_with?('}')
        params = JSON.parse(input)
        path = params["path"]
        content = params["content"] || ""
      else
        # If not JSON, assume it's a simple format like "path: content"
        return "Error: Input must be JSON with 'path' and 'content' fields. Example: {\"path\": \"file.txt\", \"content\": \"Hello\"}"
      end
    rescue JSON::ParserError => e
      return "Error parsing input: #{e.message}. Input must be JSON with 'path' and 'content' fields."
    end
    
    return "Error: path parameter is required" unless path
    
    begin
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
      "Successfully wrote to #{path}"
    rescue => e
      "Error writing file: #{e.message}"
    end
  end
end