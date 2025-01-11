# Simple Agent Ruby

A Ruby-based [ReAct](https://react-lm.github.io/) agent that integrates with LLM services.

## Prerequisites

- Ruby (latest stable version recommended)
- Bundler

## Setup

1. Clone the repository:

```bash
git clone <repository-url>
cd simple_agent_rb
```

2. Install dependencies:

```bash
bundle install
```

3. Set up environment variables:

Create a `.env` file in the root directory and add your required environment variables:

```bash
cp .env.example .env
# Edit .env with your configuration
```

## Project Structure

- `agent.rb` - Main agent implementation
- `chat_bot.rb` - Chat bot logic
- `llm_client.rb` - LLM service client implementation
- `main.rb` - Application entry point

## Running the Application

To start the application, run:

```bash
ruby main.rb
```

## Development

This project uses:

- `dotenv` for environment variable management
- `http` for making HTTP requests
- `json` for JSON parsing and generation

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
