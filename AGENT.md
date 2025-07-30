# Simple Agent Ruby - Development Guide

## Project Overview

Simple Agent Ruby is a flexible framework for building AI agents with tool-calling capabilities and enhanced text input system. The framework supports multiple LLM providers and provides professional-grade CLI input handling matching modern AI development tools.

## Quick Commands

### Running the Application
```bash
# Main agent (general purpose)
ruby bin/main.rb

# Therapy agent (specialized)
ruby bin/therapist.rb

# With specific provider and model
ruby bin/main.rb --provider openai --model gpt-4

# Enable verbose mode for debugging
ruby bin/main.rb --verbose
```

### Testing
```bash
# Run all tests
bundle exec rspec

# Run specific test suites
bundle exec rspec spec/input/
bundle exec rspec spec/input/input_handler_spec.rb
bundle exec rspec spec/input/history_manager_spec.rb
bundle exec rspec spec/input/input_validator_spec.rb
bundle exec rspec spec/input/command_processor_spec.rb
bundle exec rspec spec/input/integration_spec.rb

# Run tests with verbose output
bundle exec rspec --format documentation
```

### Installation and Setup
```bash
# Install dependencies
bundle install

# Set up environment variables
cp .env.example .env
# Edit .env with your API keys

# Verify installation
ruby bin/main.rb --help
```

## Enhanced Input System

The application now features a professional-grade text input system that replaces basic `gets.chomp` with:

### Visual Input Box
```
┌─ Chat Input ──────────────────────────────────────────────┐
│ 💭 Ready | Type your message...                           │
│   Commands: /help, /multiline, /history, /clear, /exit    │
└────────────────────────────────────────────────────────────┘
```

### Available Commands
- `/help` - Show comprehensive help
- `/multiline` - Enter multi-line input mode  
- `/code [language]` - Enter code block mode
- `/history` - Show command history
- `/search <term>` - Search command history
- `/stats` - Show history statistics
- `/export [format]` - Export history (json|text|csv)
- `/clear` - Clear screen
- `/exit` or `/quit` - Exit program

### Features
- ✅ Professional visual input boxes
- ✅ Arrow key navigation and text editing
- ✅ Persistent command history with search
- ✅ Multi-line and code block input modes
- ✅ Real-time input validation and safety checks
- ✅ Terminal resize handling
- ✅ Cross-platform compatibility

## Architecture

### Core Components

1. **Agent System** (`lib/agent/`)
   - Main orchestrator for LLM conversations
   - Tool execution and response handling
   - Support for multiple LLM providers

2. **Enhanced Input System** (`lib/input/`)
   - **InputHandler** - Main input orchestrator with visual boxes
   - **HistoryManager** - Persistent history with JSON storage
   - **CommandProcessor** - Extensible command system
   - **InputValidator** - Safety checks and content validation
   - **MultilineHandler** - Advanced input modes

3. **LLM Clients** (`lib/llm_clients/`)
   - Provider-specific API implementations
   - OpenAI, Moonshot, DeepSeek, Perplexity support

4. **Tools** (`lib/tools/`)
   - Auto-discovered tool system
   - File operations, web search, calculations
   - Extensible framework for new tools

### Input System Files
```
lib/input/
├── input_handler.rb          # Main input handling with visual boxes
├── history_manager.rb        # Persistent history management
├── command_processor.rb      # Command system framework
├── input_validator.rb        # Input validation and safety
└── multiline_handler.rb      # Multi-line and code input modes
```

## Development Workflow

### Code Style
- Follow existing Ruby conventions
- Use descriptive variable names
- Keep methods focused and single-purpose
- Add comprehensive error handling

### Testing Strategy
- Unit tests for individual components
- Integration tests for full workflows
- Performance tests for history operations
- Cross-platform compatibility tests

### Making Changes
1. Write or update tests first
2. Implement changes following existing patterns
3. Run full test suite: `bundle exec rspec`
4. Test manually with both CLI modes
5. Verify cross-platform compatibility

## Environment Variables

Required for different providers:
- `OPENAI_API_KEY` - OpenAI API access
- `MOONSHOT_API_KEY` - Moonshot API access
- `DEEPSEEK_API_KEY` - DeepSeek API access
- `PERPLEXITY_API_KEY` - Perplexity API access
- `GOOGLE_API_KEY` - Google Search Tool
- `GOOGLE_CX` - Google Custom Search Engine ID

## Performance Considerations

### Input System Optimization
- History operations: < 0.1s for 1000 entries
- Input validation: < 0.01s per input
- Terminal resize: < 0.05s response time
- Memory usage: ~2MB for full system

### History Management
- Automatic size limiting (1000 entries max)
- Efficient JSON storage format
- Fast search algorithms
- Lazy loading of components

## Troubleshooting

### Common Issues

1. **TTY Gems Not Working**
   ```bash
   bundle install
   # Ensure all TTY gems are properly installed
   ```

2. **Input Box Not Displaying**
   - Check terminal width (minimum 20 characters)
   - Try `/clear` to reset display
   - Verify TTY gem installation

3. **History Not Persisting**
   - Check file permissions in home directory
   - Use `/stats` to check history status
   - Verify disk space availability

4. **Terminal Resize Issues**
   - Some terminals may not support SIGWINCH
   - Manual `/clear` can reset display
   - Try restarting the agent

### Debug Mode
Enable verbose output for troubleshooting:
```bash
ruby bin/main.rb --verbose
```

### Performance Issues
If experiencing slow performance:
1. Check history file size: `/stats`
2. Export and clear history: `/export json` then manual cleanup
3. Temporarily disable history: modify initialization

## Contributing

### Adding New Commands
Extend the CommandProcessor class:
```ruby
# In lib/input/command_processor.rb
@commands['new_command'] = method(:cmd_new_command)

def cmd_new_command(args)
  # Implementation
  :continue
end
```

### Adding Input Validation Rules
Extend the InputValidator class:
```ruby
# In lib/input/input_validator.rb
@validators[:custom_rule] = method(:validate_custom_rule)

def validate_custom_rule(input)
  return "Custom validation failed" unless condition
  nil
end
```

### Creating New Tools
1. Create file in `lib/tools/your_tool.rb`
2. Extend Tool class and use ToolMetadata
3. Implement `call(input)` method with JSON parsing
4. Add comprehensive error handling

## Security

### Input Safety
- Dangerous command detection (rm -rf, format, etc.)
- Script injection prevention
- Sensitive data warnings (API keys, passwords)

### Safe Defaults
- Input length limits (10,000 characters)
- History size limits (1,000 entries)
- Rapid input spam prevention

## Future Enhancements

### Planned Features
- Syntax highlighting for code blocks
- Auto-completion for commands
- Input templates for common patterns
- Plugin system for extensibility
- Theme customization

### Performance Targets
- Sub-millisecond input validation
- Instant history search
- Zero-latency terminal resize
- Minimal memory footprint

---

This guide covers the essential development workflow for Simple Agent Ruby with its enhanced input system. The visual improvements and professional CLI experience make it comparable to modern AI development tools while maintaining full backward compatibility.
