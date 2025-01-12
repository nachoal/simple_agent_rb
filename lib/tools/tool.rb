# Base class for all tools in the system.
# Each tool represents a specific capability that the agent can use.
#
# To create a new tool:
# 1. Create a new class that inherits from Tool
# 2. Override the initialize method if you need custom initialization
# 3. Implement the call method with your tool's logic
#
# Example:
#   class MyTool < Tool
#     def initialize
#       super("my_tool")  # The name that will be used in prompts
#     end
#
#     def call(input)
#       # Implement your tool logic here
#       # Return a string result
#     end
#   end
class Tool
  # The name of the tool, used to identify it in prompts and commands
  attr_reader :name

  # Initialize a new tool instance
  # @param name [String, nil] The name of the tool. If nil, derives from class name
  def initialize(name = nil)
    # If no name is passed, default to class name with "Tool" stripped
    @name = name || self.class.name.downcase.gsub("tool", "")
  end

  # Execute the tool's functionality
  # @param input [String] The input to process
  # @return [String] The result of the tool's execution
  def call(_input)
    raise NotImplementedError, "Subclasses must implement #call"
  end
end 