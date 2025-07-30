# PRD: Enhanced Text Input System for Simple Agent Ruby

## Executive Summary

This PRD outlines the enhancement of the Simple Agent Ruby CLI's text input system to match the professional-grade input handling found in modern AI CLI tools like OpenAI Codex CLI, Google Gemini CLI, and Sourcegraph Amp.

## Research Findings

### Current Problem

The existing Simple Agent Ruby CLI uses basic `gets.chomp` for user input, which results in:
- **Escape character artifacts** when using arrow keys (causing "text dribble")
- **No text editing capabilities** (backspace, delete, home/end keys don't work properly)
- **No input history** or navigation
- **No multi-line input support**
- **Poor copy/paste experience**
- **No visual input box** - just "You: " text with no boundaries
- **Unprofessional user experience** compared to modern CLI tools

### Visual Comparison

#### Current Simple Agent CLI (Unprofessional)
```
You: Hi
🔄 Agent iteration 1/10
...
You: research the tunguska incident both in wiki and google give me a report
```

#### Target: Professional Input Box (Like Amp/Claude Code)
```
┌─ Chat Input ──────────────────────────────────────────────┐
│ 💭 research the tunguska incident both in wiki and goo... │
│   Ctrl+R to expand                                         │
└────────────────────────────────────────────────────────────┘

> ▶                                        ? for shortcuts
```

### How Modern AI CLI Tools Handle Input

#### 1. OpenAI Codex CLI
- **Technology**: Rust + `ratatui` TUI library
- **Features**: 
  - Rich terminal interfaces with text input boxes
  - Full arrow key navigation support
  - Multi-line input with proper cursor management
  - Built-in history navigation and text editing capabilities

#### 2. Google Gemini CLI
- **Technology**: Node.js + `@inquirer/prompts`
- **Features**:
  - Interactive prompts leveraging Node.js `readline` module
  - Color-coded text input with validation
  - Arrow key navigation and text editing
  - Professional input boxes

#### 3. Common Patterns Across Modern CLI Tools
- Use dedicated TUI libraries instead of basic input methods
- Text input handled in visual "boxes" or dedicated input areas
- Standard keyboard shortcuts work as expected (arrow keys, home/end, backspace)
- History navigation (up/down arrows) is standard
- Multi-line input support with proper line editing

### Ruby Terminal Input Ecosystem Analysis

#### TTY Ecosystem (Recommended Solution)
- **`tty-prompt`**: Beautiful interactive prompts with extensive features
- **`tty-reader`**: Low-level keyboard input handling with readline functionality  
- **`tty-cursor`**: Terminal cursor positioning and manipulation

#### Key Features of TTY-Prompt
- ✅ Text input boxes with arrow key navigation
- ✅ Multi-line input support
- ✅ Input validation and conversion
- ✅ History tracking and navigation
- ✅ Cross-platform compatibility (Linux, macOS, Windows)
- ✅ Color and styling support
- ✅ Event-driven keyboard handling
- ✅ Pure Ruby implementation (no external dependencies)

## Goals and Objectives

### Primary Goals
1. **Eliminate input artifacts** when using arrow keys and navigation
2. **Provide professional text editing experience** matching modern CLI tools
3. **Add input history and navigation** for improved productivity
4. **Support multi-line input** for complex prompts
5. **Maintain backward compatibility** with existing functionality

### Success Metrics
- ✅ No escape character artifacts when using arrow keys
- ✅ Smooth text editing experience matching modern CLI tools
- ✅ Persistent input history across sessions
- ✅ Multi-line input support for complex prompts
- ✅ Zero regression in existing functionality
- ✅ Cross-platform compatibility maintained

## Technical Requirements

### Core Requirements

#### 1. Visual Input Box Design
- **Bordered input box** with clear visual boundaries like Amp and Claude Code
- **Visual separation** between chat content and input area
- **Professional styling** with consistent branding and colors
- **Dynamic box sizing** that adapts to terminal width
- **Terminal resize handling** with automatic rerendering and layout updates
- **Input prompt styling** with icons and visual indicators
- **Responsive design** that gracefully handles small and large terminal sizes

#### 2. Rich Text Input
- **Single-line input** with full text editing capabilities
- **Arrow key navigation** (left/right within line, up/down for history)
- **Standard editing keys**: Home, End, Ctrl+A, Ctrl+E, Backspace, Delete
- **Copy/paste support** with proper terminal integration
- **Real-time input validation** with visual feedback

#### 3. Multi-line Input Support
- **Multi-line mode** for long prompts/questions
- **Ctrl+D or Ctrl+Z** to submit multi-line input
- **Line-by-line editing** within multi-line context
- **Visual indicators** for multi-line mode
- **Expandable input box** for multi-line content

#### 4. Input History
- **Session history** for up/down arrow navigation
- **Persistent history** across agent sessions
- **History search** with Ctrl+R (reverse search)
- **History size limits** (configurable)

#### 5. User Experience Enhancements
- **Input validation** with real-time feedback
- **Command shortcuts** (/help, /multiline, /history, /clear, /exit)
- **Progress indicators** during agent processing
- **Error handling** with graceful fallbacks
- **Status indicators** showing agent state (thinking, typing, etc.)

## Implementation Plan

### Phase 1: Core Input Replacement (Week 1)

#### Dependencies
```ruby
# Add to Gemfile
gem 'tty-prompt', '~> 0.23'    # Interactive prompts
gem 'tty-reader', '~> 0.9'     # Keyboard input handling
gem 'tty-cursor', '~> 0.7'     # Cursor positioning
gem 'tty-box', '~> 0.7'        # Visual input boxes
gem 'tty-screen', '~> 0.8'     # Terminal dimensions and resize detection
```

#### Visual Input Box Implementation
```ruby
# lib/input/input_handler.rb
require 'tty-prompt'
require 'tty-box'
require 'tty-screen'
require 'tty-cursor'

class InputHandler
  def initialize
    @prompt = TTY::Prompt.new(
      symbols: { marker: "▶" },
      active_color: :cyan,
      help_color: :dim
    )
    @reader = TTY::Reader.new
    @cursor = TTY::Cursor
    @screen = TTY::Screen
    @current_input = ""
    @input_box_rendered = false
    setup_resize_handler
  end

  def read_input_with_box(agent_status: "Ready")
    # Create visual input box like Amp/Claude Code
    create_input_box do
      @prompt.ask("💭", required: true) do |q|
        q.modify :strip
        q.validate /\S+/, "Please enter a message"
        q.default ""
      end
    end
  end

  private

  def create_input_box(&block)
    box_width = [@screen.width - 4, 80].min
    
    # Create bordered box for input
    input_box = TTY::Box.frame(
      width: box_width,
      height: 3,
      border: :light,
      style: {
        border: {
          fg: :cyan
        }
      },
      title: { 
        top_left: " Chat Input ",
        fg: :bright_blue
      }
    ) do
      "#{@cursor.move_to(1, 0)}💭 Type your message..."
    end

    # Display the box
    puts input_box
    
    # Position cursor inside box and get input
    print @cursor.move_up(2) + @cursor.move_right(3)
    result = yield
    
    # Clear the input box and return result
    clear_input_area
    result
  end

  def clear_input_area
    print @cursor.move_up(3)
    print @cursor.clear_lines(3)
    @input_box_rendered = false
  end

  def setup_resize_handler
    # Handle terminal resize events (SIGWINCH)
    Signal.trap('WINCH') do
      handle_terminal_resize
    end
  end

  def handle_terminal_resize
    return unless @input_box_rendered
    
    # Store current cursor position and input state
    current_input = @current_input
    
    # Clear current input box
    clear_input_area
    
    # Redraw with new terminal dimensions
    rerender_input_box(current_input)
  end

  def rerender_input_box(preserved_input = "")
    # Recalculate box dimensions for new terminal size
    box_width = [@screen.width - 4, 80].min
    
    # Handle minimum width constraints
    if box_width < 20
      # Fallback to simple prompt for very small terminals
      @prompt.ask("💭", value: preserved_input, required: true)
    else
      # Recreate box with new dimensions
      create_input_box_with_content(preserved_input)
    end
  end

  def create_input_box_with_content(content = "")
    box_width = [@screen.width - 4, 80].min
    
    input_box = TTY::Box.frame(
      width: box_width,
      height: calculate_box_height(content, box_width),
      border: :light,
      style: {
        border: { fg: :cyan }
      },
      title: { 
        top_left: " Chat Input ",
        fg: :bright_blue
      }
    ) do
      format_content_for_box(content, box_width)
    end

    puts input_box
    @input_box_rendered = true
  end

  def calculate_box_height(content, box_width)
    # Calculate required height based on content length and box width
    content_width = box_width - 4  # Account for padding
    lines_needed = (content.length / content_width.to_f).ceil
    [lines_needed + 1, 10].min  # Min 2 lines, max 10 lines
  end

  def format_content_for_box(content, box_width)
    # Handle text wrapping within the box
    content_width = box_width - 4
    if content.length <= content_width
      "💭 #{content}"
    else
      wrapped = content.scan(/.{1,#{content_width}}/)
      wrapped.map.with_index { |line, i| 
        i == 0 ? "💭 #{line}" : "  #{line}" 
      }.join("\n")
    end
  end
end
```

#### Integration Points
- Replace `gets.chomp` in `bin/main.rb`
- Replace `gets.chomp` in `bin/therapist.rb`
- Add input mode selection (single vs multi-line)
- Integrate with agent conversation flow

### Phase 2: History Integration (Week 2)

#### Features
- Implement persistent history using file storage
- Add history navigation with up/down arrows
- Integrate with existing agent conversation history
- History search functionality

#### Implementation
```ruby
class InputHandler
  def initialize(enable_history: true, history_file: nil)
    @prompt = TTY::Prompt.new(
      symbols: { 
        marker: "▶",
        radio_on: "●", 
        radio_off: "○"
      },
      active_color: :cyan,
      help_color: :dim
    )
    @enable_history = enable_history
    @history_file = history_file || default_history_file
    load_history if @enable_history
  end

  private

  def default_history_file
    File.join(Dir.home, '.simple_agent_history')
  end

  def load_history
    # Implementation for loading command history
  end
end
```

### Phase 3: Advanced Features (Week 3-4)

#### Enhanced UX Features
```ruby
class InputHandler
  def prompt_with_context(agent_status: nil)
    status_line = agent_status ? bright_black("#{agent_status} | ") : ""
    message = "#{status_line}#{cyan('You:')} "
    
    # Show available options
    puts dim("  Commands: /help, /multiline, /history, /clear, /exit")
    
    input = read_single_line(message: message)
    
    # Handle special commands
    case input
    when '/multiline'
      read_multiline
    when '/help'
      show_help
      prompt_with_context(agent_status: agent_status)
    when '/history'
      show_history
      prompt_with_context(agent_status: agent_status)
    when '/clear'
      clear_screen
      prompt_with_context(agent_status: agent_status)
    when '/exit'
      exit(0)
    else
      input
    end
  end
end
```

#### Advanced Features
- Multi-line input mode with toggle
- Input validation and error feedback
- Visual improvements and styling
- Performance optimization
- Command auto-completion

### Phase 4: Future Enhancements

#### Potential Future Features
- **Syntax highlighting** for code blocks
- **Auto-completion** for common commands
- **Input templates** for common prompt patterns
- **Collaborative input** for team sessions
- **Plugin system** for custom input handlers

## Risk Assessment and Mitigation

### Risks
1. **Cross-platform compatibility issues**
2. **Performance degradation** with large input history
3. **Breaking changes** to existing workflows
4. **Terminal compatibility** across different environments

### Mitigation Strategies
- **Fallback mechanism**: Keep original `gets.chomp` as backup
- **Cross-platform testing**: Test on macOS, Linux, Windows
- **Performance monitoring**: Ensure no input lag
- **Gradual rollout**: Implement behind feature flag initially
- **Comprehensive testing**: Unit and integration tests for all input scenarios

## File Structure

```
lib/
├── input/
│   ├── input_handler.rb          # Main input handling class
│   ├── history_manager.rb        # History persistence and management
│   ├── multiline_handler.rb      # Multi-line specific functionality
│   └── command_processor.rb      # Special command handling
├── agent/
│   ├── agent.rb                  # Updated to use InputHandler
│   └── configurable_agent.rb     # Updated to use InputHandler
bin/
├── main.rb                       # Updated CLI interface
└── therapist.rb                  # Updated therapy CLI interface
docs/
└── PRD_Enhanced_Text_Input.md    # This document
```

## Testing Strategy

### Unit Tests
- Input validation and sanitization
- History management functionality
- Multi-line input handling
- Command processing
- Terminal resize handling and state preservation

### Integration Tests
- Agent conversation flow with new input
- Cross-platform compatibility
- Performance under load
- Error handling and recovery
- Terminal resize scenarios during active input

### Terminal Resize Testing
- **Dynamic resizing** during text input (preserve content)
- **Minimum width handling** (graceful fallback to simple prompt)
- **Maximum width constraints** (content wrapping and layout)
- **Height adjustments** for multi-line content
- **Signal handling** (SIGWINCH response time and accuracy)
- **Content preservation** during resize events

### User Acceptance Testing
- Compare UX with modern CLI tools (Codex, Gemini CLI)
- Verify arrow key functionality
- Test copy/paste operations
- Validate multi-line input workflows

## Success Criteria

✅ **No escape character artifacts** when using arrow keys  
✅ **Professional text editing** experience matching Codex CLI and Gemini CLI  
✅ **Persistent input history** across agent sessions  
✅ **Multi-line input** support for complex prompts  
✅ **Dynamic terminal resizing** with automatic layout updates  
✅ **Content preservation** during terminal resize events  
✅ **Cross-platform compatibility** maintained  
✅ **Zero performance regression** in agent response times  
✅ **Backward compatibility** with existing scripts and workflows  

## Timeline

- **Week 1**: Core input replacement and basic functionality
- **Week 2**: History integration and navigation
- **Week 3**: Advanced features and UX improvements
- **Week 4**: Testing, optimization, and documentation

## Conclusion

This enhancement will elevate the Simple Agent Ruby CLI to match the professional standards of modern AI development tools. By implementing the TTY ecosystem, we'll provide users with a smooth, professional text input experience that eliminates current frustrations and enables more productive interactions with the agent.

The phased approach ensures minimal risk while delivering immediate value, positioning Simple Agent Ruby as a professional-grade tool comparable to industry-leading AI CLI applications.
