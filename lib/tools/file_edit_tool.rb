require_relative 'tool'
require 'json'
require 'fileutils'

class FileEditTool < Tool
  extend ToolMetadata
  
  describe :call, "Edit a file by replacing old_str with new_str. Input must be JSON with 'path', 'old_str', and 'new_str' fields. Example: {\"path\": \"file.txt\", \"old_str\": \"old\", \"new_str\": \"new\"}"
  
  def initialize
    super("file_edit")
  end
  
  def call(input)
    begin
      params = JSON.parse(input)
      path = params["path"]
      old_str = params["old_str"] || ""
      new_str = params["new_str"] || ""
    rescue JSON::ParserError => e
      return "Error parsing input: #{e.message}. Input must be JSON with 'path', 'old_str', and 'new_str' fields."
    end
    
    return "Error: path parameter is required" unless path
    return "Error: old_str and new_str must be different" if old_str == new_str
    
    begin
      if File.exist?(path)
        content = File.read(path)
        
        if old_str.empty?
          return "Error: Cannot use empty old_str on existing file"
        end
        
        unless content.include?(old_str)
          return "Error: old_str not found in file"
        end
        
        new_content = content.gsub(old_str, new_str)
        File.write(path, new_content)
        "OK"
      else
        # Create new file
        return "Error: old_str must be empty when creating new file" unless old_str.empty?
        
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, new_str)
        "Successfully created file #{path}"
      end
    rescue => e
      "Error editing file: #{e.message}"
    end
  end
end