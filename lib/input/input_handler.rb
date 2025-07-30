require 'tty-prompt'
require 'tty-box'
require 'tty-screen'
require 'tty-cursor'
require 'tty-reader'
require_relative 'history_manager'
require_relative 'command_processor'
require_relative 'input_validator'

class InputHandler
  def initialize(enable_history: true, history_file: nil)
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
    @enable_history = enable_history
    @history_manager = HistoryManager.new(history_file) if @enable_history
    @command_processor = CommandProcessor.new(self, @history_manager)
    @input_validator = InputValidator.new
    setup_resize_handler
  end

  def read_input(prompt_text: "You: ", agent_status: "Ready")
    # Create the actual input box where user types inside
    input = create_interactive_input_box(agent_status)

    return nil if input.nil? || input.empty?
    
    # Process commands
    if input.start_with?('/')
      result = @command_processor.process_command(input)
      return read_input(prompt_text: prompt_text, agent_status: agent_status) if result == :continue
      return result if result.is_a?(String)
      return nil  # For exit commands
    end
    
    # Validate input
    validation = @input_validator.validate(input)
    
    unless validation[:valid]
      puts "\n❌ Input validation failed:".colorize(:red)
      validation[:errors].each { |error| puts "  • #{error}".colorize(:red) }
      puts
      return read_input(prompt_text: prompt_text, agent_status: agent_status)
    end
    
    # Show warnings if any
    unless validation[:warnings].empty?
      validation[:warnings].each { |warning| puts "#{warning}".colorize(:yellow) }
      puts
    end
    
    # Show suggestions for improvement
    suggestions = @input_validator.suggest_improvements(input)
    unless suggestions.empty?
      suggestions.each { |suggestion| puts "#{suggestion}".colorize(:cyan) }
      puts
    end
    
    # Add regular input to history
    @history_manager&.add_entry(input)
    input
  end

  def read_multiline
    puts "\n📝 Multi-line input mode (Ctrl+D or type 'END' on a new line to finish):\n".colorize(:yellow)
    lines = []
    
    loop do
      print "│ ".colorize(:dim)
      line = gets.chomp
      break if line == 'END' || line.nil?
      lines << line
    end
    
    input = lines.join("\n")
    @history_manager&.add_entry(input) unless input.empty?
    input
  end

  private

  def create_interactive_input_box(agent_status)
    # Simple, clean approach - just a colored prompt with better input handling
    status_text = agent_status ? "[#{agent_status}] " : ""
    prompt_text = "#{status_text}You: ".colorize(:green)
    
    # Show available commands as a helpful hint (only on first run or after commands)
    unless @commands_shown_recently
      puts "\nCommands: /help, /multiline, /history, /clear, /exit".colorize(:dim)
      @commands_shown_recently = true
    end
    
    # Use TTY::Prompt for proper input handling (arrow keys, backspace, etc.)
    begin
      input = @prompt.ask(prompt_text, required: false) do |q|
        q.modify :strip
        q.default ""
      end
      
      # Reset command hint flag if user runs a command
      @commands_shown_recently = false if input&.start_with?('/')
      
      input || ""
    rescue Interrupt
      puts "\n^C"
      ""
    rescue TTY::Reader::InputInterrupt
      puts "\n^C"  
      ""
    rescue => e
      # Fallback to basic input if TTY::Prompt fails
      print prompt_text
      begin
        gets.chomp
      rescue
        ""
      end
    end
  end

  def setup_resize_handler
    # Handle terminal resize events (SIGWINCH) - simplified for compatibility
    Signal.trap('WINCH') do
      # Just continue - no complex resize handling needed for simple prompt
    end
  rescue ArgumentError
    # SIGWINCH might not be available on all platforms
  end

  def show_help
    puts "\n" + "=" * 60
    puts "📋 Simple Agent Ruby - Enhanced Input Help".colorize(:cyan)
    puts "=" * 60
    puts
    puts "Commands:".colorize(:yellow)
    puts "  /help          - Show this help message"
    puts "  /multiline     - Enter multi-line input mode"
    puts "  /history       - Show input history"
    puts "  /search <term> - Search command history"
    puts "  /clear         - Clear the screen"
    puts "  /exit          - Exit the program"
    puts "  /quit          - Exit the program"
    puts
    puts "Input Features:".colorize(:yellow)
    puts "  • Arrow keys for text navigation"
    puts "  • Up/Down arrows for history navigation"
    puts "  • Home/End keys for line navigation"
    puts "  • Backspace/Delete for text editing"
    puts "  • Copy/paste support"
    puts "  • Multi-line input with /multiline command"
    puts
    puts "Tips:".colorize(:yellow)
    puts "  • Use /multiline for long prompts or code blocks"
    puts "  • History is automatically saved between sessions"
    puts "  • Terminal resize is automatically handled"
    puts "=" * 60
    puts
  end

  def show_history
    return unless @history_manager
    
    recent = @history_manager.get_recent(10)
    stats = @history_manager.get_stats
    
    if recent.empty?
      puts "\n📜 No command history available".colorize(:yellow)
      return
    end
    
    puts "\n📜 Command History (last 10 entries):".colorize(:cyan)
    puts "=" * 60
    
    recent.each_with_index do |cmd, index|
      actual_index = stats[:total_entries] - 10 + index + 1
      truncated = cmd.length > 70 ? "#{cmd[0..67]}..." : cmd
      puts "  #{actual_index}. #{truncated}".colorize(:light_blue)
    end
    
    puts "=" * 60
    puts "📊 Stats: #{stats[:total_entries]} total entries, #{stats[:current_session_entries]} this session".colorize(:dim)
    puts "💡 Use /search <term> to find specific commands".colorize(:dim)
    puts
  end

  def clear_screen
    system('clear') || system('cls')
    puts "Welcome to the AI agent. Type 'exit' to quit".colorize(:blue)
    puts "Use /help for available commands".colorize(:dim)
    puts
  end
end
