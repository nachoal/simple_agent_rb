module FunctionSchemaGenerator
  def self.generate(tool_class)
    # Check if the tool class has defined its schema
    if tool_class.respond_to?(:schema)
      return tool_class.schema
    end
    
    # Default schema for backward compatibility
    {
      "type" => "function",
      "function" => {
        "name" => tool_class.new.name,
        "description" => tool_class.description_for(:call) || "No description provided.",
        "parameters" => {
          "type" => "object",
          "properties" => {
            "input" => {
              "type" => "string",
              "description" => "Input for the tool"
            }
          },
          "required" => ["input"],
          "additionalProperties" => false
        },
        "strict" => true
      }
    }
  end
end