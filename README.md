# Simple Agent RB

A Ruby-based AI agent that can perform various tasks through a collection of tools and different LLM providers.

## Features

- Multiple LLM Provider Support:
  - OpenAI (GPT-4)
  - DeepSeek
  - Perplexity
- Built-in Tools:
  - Wikipedia Search
  - Google Search
  - Simon Willison's Blog Search
  - Safe Calculator

## Prerequisites

- Ruby 3.0+
- Required API Keys:
  - OpenAI API Key (for OpenAI)
  - DeepSeek API Key (for DeepSeek)
  - Perplexity API Key (for Perplexity)
  - Google Search API Key and Search Engine ID (for Google Search)

## Installation

1. Clone the repository:

```bash
git clone https://github.com/yourusername/simple_agent_rb.git
cd simple_agent_rb
```

2. Install dependencies:

```bash
bundle install
```

3. Set up your environment variables:

```bash
cp .env.example .env
```

Edit `.env` and add your API keys:

```
OPENAI_API_KEY=your_openai_key
DEEPSEEK_API_KEY=your_deepseek_key
PERPLEXITY_API_KEY=your_perplexity_key
GOOGLE_SEARCH_API_KEY=your_google_key
GOOGLE_SEARCH_ENGINE_ID=your_search_engine_id
```

## Usage

Run the agent:

```bash
ruby bin/main.rb
```

By default, the agent uses DeepSeek. You can modify `bin/main.rb` to use a different provider:

```ruby
# Use OpenAI
agent = Agent.new(:openai)

# Use Perplexity
agent = Agent.new(:perplexity)

# Specify a model
agent = Agent.new(:openai, "gpt-4")
```

## Project Structure

```
simple_agent_rb/
├── bin/
│   └── main.rb              # Entry point
└── lib/
    ├── agent/
    │   └── agent.rb         # Main agent logic
    ├── llm_clients/         # LLM providers
    │   ├── llm_client.rb    # Base LLM client
    │   ├── openai_client.rb
    │   ├── deepseek_client.rb
    │   └── perplexity_client.rb
    └── tools/               # Available tools
        ├── tool.rb          # Base tool class
        ├── tool_registry.rb # Tool management
        ├── wikipedia_tool.rb
        ├── google_search_tool.rb
        ├── simon_blog_search_tool.rb
        └── calculate_tool.rb
```

## Adding New Tools

1. Create a new tool class in `lib/tools/` that inherits from `Tool`:

```ruby
require_relative "tool"

class MyNewTool < Tool
  def initialize
    super("my_new_tool")  # The name used in prompts
  end

  def call(input)
    # Implement your tool logic here
  end
end
```

2. The tool will be automatically registered and available to use.

## Adding New LLM Providers

1. Create a new client class in `lib/llm_clients/` that inherits from `LLMClient`:

```ruby
require_relative "llm_client"

class MyNewClient < LLMClient
  def initialize(system = "", model = nil)
    super(system, model)
    @api_key = ENV["MY_NEW_API_KEY"]
  end

  private

  def execute
    # Implement your API call here
  end
end
```

2. Update `Agent#create_llm_client` to support your new provider.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -am 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
