require 'colorize'

class CommandProcessor
  def initialize(input_handler, history_manager)
    @input_handler = input_handler
    @history_manager = history_manager
    @commands = {
      'help' => method(:cmd_help),
      'multiline' => method(:cmd_multiline), 
      'code' => method(:cmd_code),
      'history' => method(:cmd_history),
      'search' => method(:cmd_search),
      'stats' => method(:cmd_stats),
      'export' => method(:cmd_export),
      'clear' => method(:cmd_clear),
      'exit' => method(:cmd_exit),
      'quit' => method(:cmd_exit)
    }
  end

  def process_command(input)
    return input unless input.start_with?('/')
    
    # Parse command and arguments
    parts = input[1..-1].split(' ', 2)
    command = parts[0].downcase
    args = parts[1] || ''
    
    if @commands.key?(command)
      result = @commands[command].call(args)
      return :continue if result == :continue
      result
    else
      puts "\n❌ Unknown command: /#{command}".colorize(:red)
      puts "💡 Type /help for available commands".colorize(:dim)
      :continue
    end
  end

  def list_commands
    @commands.keys.sort
  end

  private

  def cmd_help(args)
    puts "\n" + "=" * 70
    puts "📋 Simple Agent Ruby - Enhanced Input Commands".colorize(:cyan)
    puts "=" * 70
    puts
    puts "Basic Commands:".colorize(:yellow)
    puts "  /help              - Show this help message"
    puts "  /clear             - Clear the screen"
    puts "  /exit, /quit       - Exit the program"
    puts
    puts "Input Commands:".colorize(:yellow)
    puts "  /multiline         - Enter multi-line input mode"
    puts "  /code [language]   - Enter code block input mode"
    puts
    puts "History Commands:".colorize(:yellow)
    puts "  /history           - Show recent command history"
    puts "  /search <term>     - Search command history"
    puts "  /stats             - Show history statistics"
    puts "  /export [format]   - Export history (json|text|csv)"
    puts
    puts "Input Features:".colorize(:yellow)
    puts "  • Arrow keys for text navigation and history"
    puts "  • Home/End keys for line navigation"
    puts "  • Backspace/Delete for text editing"
    puts "  • Copy/paste support"
    puts "  • Automatic input validation"
    puts "  • Terminal resize handling"
    puts
    puts "Tips:".colorize(:yellow)
    puts "  • Use /multiline for long prompts or multiple paragraphs"
    puts "  • Use /code for code blocks with syntax preservation"
    puts "  • History is automatically saved between sessions"
    puts "  • Commands are case-insensitive"
    puts "=" * 70
    puts
    :continue
  end

  def cmd_multiline(args)
    require_relative 'multiline_handler'
    multiline_handler = MultilineHandler.new
    multiline_handler.read_multiline_input
  end

  def cmd_code(args)
    require_relative 'multiline_handler'
    multiline_handler = MultilineHandler.new
    language = args.strip.empty? ? nil : args.strip
    
    result = multiline_handler.read_code_block(language)
    return result if result
    
    :continue
  end

  def cmd_history(args)
    return :continue unless @history_manager
    
    recent = @history_manager.get_recent(15)
    stats = @history_manager.get_stats
    
    if recent.empty?
      puts "\n📜 No command history available".colorize(:yellow)
      return :continue
    end
    
    puts "\n📜 Command History (last 15 entries):".colorize(:cyan)
    puts "=" * 70
    
    recent.each_with_index do |cmd, index|
      actual_index = stats[:total_entries] - 15 + index + 1
      truncated = cmd.length > 60 ? "#{cmd[0..57]}..." : cmd
      timestamp = Time.now.strftime("%H:%M")  # Simplified for recent items
      
      puts "  #{actual_index.to_s.rjust(3)}. [#{timestamp}] #{truncated}".colorize(:light_blue)
    end
    
    puts "=" * 70
    puts "📊 Total: #{stats[:total_entries]} entries | This session: #{stats[:current_session_entries]}".colorize(:dim)
    puts "💡 Use /search <term> to find specific commands".colorize(:dim)
    puts
    :continue
  end

  def cmd_search(args)
    return :continue unless @history_manager
    
    if args.strip.empty?
      puts "\n❌ Please provide a search term: /search <term>".colorize(:red)
      return :continue
    end
    
    results = @history_manager.search(args.strip)
    if results
      puts "\n🔍 Search results for '#{args.strip}':".colorize(:cyan)
      puts "=" * 70
      
      # Show first result
      truncated = results.length > 80 ? "#{results[0..77]}..." : results
      puts "  Found: #{truncated}".colorize(:light_blue)
      puts "  💡 Use arrow keys to navigate through results".colorize(:dim)
      puts "=" * 70
    else
      puts "\n🔍 No results found for '#{args.strip}'".colorize(:yellow)
      puts "💡 Try a different search term or check /history".colorize(:dim)
    end
    puts
    :continue
  end

  def cmd_stats(args)
    return :continue unless @history_manager
    
    stats = @history_manager.get_stats
    
    puts "\n📊 History Statistics:".colorize(:cyan)
    puts "=" * 50
    puts "  Total entries: #{stats[:total_entries]}"
    puts "  This session:  #{stats[:current_session_entries]}"
    
    if stats[:oldest_entry]
      oldest = Time.at(stats[:oldest_entry]).strftime("%Y-%m-%d %H:%M:%S")
      puts "  Oldest entry:  #{oldest}"
    end
    
    if stats[:newest_entry]
      newest = Time.at(stats[:newest_entry]).strftime("%Y-%m-%d %H:%M:%S")
      puts "  Newest entry:  #{newest}"
    end
    
    puts "=" * 50
    puts
    :continue
  end

  def cmd_export(args)
    return :continue unless @history_manager
    
    format = args.strip.downcase
    format = 'json' if format.empty?
    
    unless %w[json text csv].include?(format)
      puts "\n❌ Invalid format. Use: json, text, or csv".colorize(:red)
      return :continue
    end
    
    begin
      exported_data = @history_manager.export_history(format.to_sym)
      filename = "simple_agent_history_#{Time.now.strftime('%Y%m%d_%H%M%S')}.#{format}"
      
      File.write(filename, exported_data)
      puts "\n✅ History exported to: #{filename}".colorize(:green)
      puts "📄 Format: #{format.upcase}".colorize(:dim)
      
    rescue => e
      puts "\n❌ Export failed: #{e.message}".colorize(:red)
    end
    
    puts
    :continue
  end

  def cmd_clear(args)
    system('clear') || system('cls')
    puts "🤖 Simple Agent Ruby - Enhanced Input System".colorize(:blue)
    puts "Type /help for available commands".colorize(:dim)
    puts "=" * 50
    puts
    :continue
  end

  def cmd_exit(args)
    puts "\n👋 Goodbye! Thanks for using Simple Agent Ruby.".colorize(:green)
    exit(0)
  end
end
