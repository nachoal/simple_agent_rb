require "json"
require_relative "./lib/tools/function_serializer"
require_relative "./lib/tools/calculate_tool"
require_relative "./lib/tools/google_search_tool"

def usage_example
  # Example with CalculateTool that has metadata
  calc_method_obj = CalculateTool.instance_method(:call)
  calc_method_json = function_to_json(calc_method_obj)
  puts "CalculateTool#call function definition:"
  puts JSON.pretty_generate(calc_method_json)
  puts "\n"

  # Example with GoogleSearchTool for comparison
  search_method_obj = GoogleSearchTool.instance_method(:call)
  search_method_json = function_to_json(search_method_obj)
  puts "GoogleSearchTool#call function definition:"
  puts JSON.pretty_generate(search_method_json)
end

# Run the example
usage_example