# Registry for managing and accessing tools.
# This class is implemented as a singleton to ensure only one instance exists.
# It automatically discovers and loads all tool classes in the tools directory.
#
# Usage:
#   # Get the registry instance
#   registry = ToolRegistry.instance
#
#   # Get a specific tool
#   calculator = registry.fetch("calculate")
#
#   # Get all registered tools
#   all_tools = registry.tools
require "singleton"
require "pathname"
require_relative "tool"
require_relative "tool_metadata"

class ToolRegistry
  include Singleton
  extend ToolMetadata

  describe :fetch, "Retrieves a tool instance by its name, raising an error if the tool doesn't exist."
  describe :tools, "Returns a hash of all registered tools, mapping tool names to their instances."

  # Initialize the registry and load all available tools
  def initialize
    @tools = {}
    load_tools
  end

  # Fetch a tool by name
  # @param tool_name [String] The name of the tool to fetch
  # @return [Tool] The requested tool instance
  # @raise [RuntimeError] if the tool doesn't exist
  def fetch(tool_name)
    @tools[tool_name] || raise("Unknown tool: #{tool_name}")
  end

  # Get all registered tools
  # @return [Hash<String, Tool>] A hash mapping tool names to tool instances
  def tools
    @tools
  end

  private

  # Load all tool classes from the tools directory
  # This method:
  # 1. Finds all .rb files in the tools directory (except base classes)
  # 2. Requires each file to load the tool classes
  # 3. Creates instances of each tool class and registers them
  def load_tools
    # Get all .rb files in the tools directory except tool.rb and tool_registry.rb
    tool_files = Pathname.new(__dir__).glob("*.rb").reject do |file|
      ["tool.rb", "tool_registry.rb"].include?(file.basename.to_s)
    end

    # Require all tool files
    tool_files.each { |file| require file }

    # Register each subclass of Tool
    ObjectSpace.each_object(Class).select { |klass| klass < Tool }.each do |tool_class|
      tool_instance = tool_class.new
      @tools[tool_instance.name] = tool_instance
    end
  end
end 