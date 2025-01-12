# Base class for all LLM (Language Learning Model) clients.
# This class provides a common interface for interacting with different LLM providers.
#
# To implement a new LLM client:
# 1. Create a new class that inherits from LLMClient
# 2. Override initialize if you need custom initialization
# 3. Implement the private execute method to handle API communication
#
# Example:
#   class MyLLMClient < LLMClient
#     def initialize(system = "", model = nil)
#       super(system, model)
#       @api_key = ENV["MY_API_KEY"]
#     end
#
#     private
#
#     def execute
#       # Implement your API call here
#       # Return the model's response as a string
#     end
#   end
class LLMClient
  # Initialize a new LLM client
  # @param system [String] The system prompt to use
  # @param model [String, nil] The specific model to use, if any
  def initialize(system = "", model = nil)
    @system = system
    @model = model
    @messages = []
    @messages << { role: "system", content: system } if !@system.empty?
  end

  # Send a message to the LLM and get a response
  # @param message [String] The message to send
  # @return [String] The LLM's response
  def call(message)
    @messages << { role: "user", content: message }
    result = execute
    @messages << { role: "assistant", content: result }
    result
  end

  private

  # Execute the actual API call to the LLM provider
  # @return [String] The model's response
  # @raise [NotImplementedError] if the subclass doesn't implement this method
  def execute
    raise NotImplementedError, "Subclasses must implement execute"
  end
end 