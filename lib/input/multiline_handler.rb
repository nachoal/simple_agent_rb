require 'tty-prompt'
require 'tty-box'
require 'tty-screen'
require 'tty-cursor'

class MultilineHandler
  def initialize
    @prompt = TTY::Prompt.new(
      symbols: { marker: "▶" },
      active_color: :cyan,
      help_color: :dim
    )
    @cursor = TTY::Cursor
    @screen = TTY::Screen
  end

  def read_multiline_input
    lines = []
    puts "\n📝 Multi-line input mode".colorize(:yellow)
    puts "=" * 60
    puts "Tips:".colorize(:cyan)
    puts "  • Type your message across multiple lines"
    puts "  • Type 'END' on a new line to finish"
    puts "  • Type 'CANCEL' to cancel input"
    puts "  • Empty line + Enter twice also finishes"
    puts "=" * 60
    puts
    
    empty_line_count = 0
    line_number = 1
    
    loop do
      print format_line_prompt(line_number)
      line = gets.chomp
      
      case line.upcase
      when 'END'
        break
      when 'CANCEL'
        puts "\n❌ Input cancelled".colorize(:red)
        return nil
      when ''
        empty_line_count += 1
        if empty_line_count >= 2
          puts "\n✅ Input completed (two empty lines)".colorize(:green)
          break
        end
        lines << line
      else
        empty_line_count = 0
        lines << line
      end
      
      line_number += 1
    end
    
    # Remove trailing empty lines
    while lines.last&.empty?
      lines.pop
    end
    
    result = lines.join("\n")
    
    if result.strip.empty?
      puts "\n⚠️  Empty input detected".colorize(:yellow)
      return nil
    end
    
    show_preview(result)
    result
  end

  def read_code_block(language = nil)
    puts "\n💻 Code block input mode#{language ? " (#{language})" : ''}".colorize(:yellow)
    puts "=" * 60
    puts "Tips:".colorize(:cyan)
    puts "  • Paste or type your code"
    puts "  • Type '```' on a new line to finish"
    puts "  • Proper indentation will be preserved"
    puts "=" * 60
    puts
    
    lines = []
    line_number = 1
    
    loop do
      print format_code_prompt(line_number)
      line = gets.chomp
      
      if line.strip == '```'
        break
      end
      
      lines << line
      line_number += 1
    end
    
    result = lines.join("\n")
    
    if result.strip.empty?
      puts "\n⚠️  Empty code block detected".colorize(:yellow)
      return nil
    end
    
    show_code_preview(result, language)
    result
  end

  private

  def format_line_prompt(line_number)
    "#{line_number.to_s.rjust(3)}│ ".colorize(:dim)
  end

  def format_code_prompt(line_number)
    "#{line_number.to_s.rjust(3)}│ ".colorize(:blue)
  end

  def show_preview(text)
    max_lines = 5
    lines = text.split("\n")
    
    puts "\n📋 Preview:".colorize(:cyan)
    puts "┌─ Input Preview " + "─" * (@screen.width - 18)
    
    if lines.length <= max_lines
      lines.each { |line| puts "│ #{line}" }
    else
      lines.first(max_lines - 1).each { |line| puts "│ #{line}" }
      puts "│ ... (#{lines.length - max_lines + 1} more lines)"
    end
    
    puts "└" + "─" * (@screen.width - 2)
    puts "📊 Total: #{text.length} characters, #{lines.length} lines".colorize(:dim)
    puts
  end

  def show_code_preview(code, language)
    lines = code.split("\n")
    
    puts "\n💻 Code Preview#{language ? " (#{language})" : ''}:".colorize(:cyan)
    puts "```#{language || ''}"
    
    # Show first 10 lines
    display_lines = lines.first(10)
    display_lines.each_with_index do |line, i|
      line_num = (i + 1).to_s.rjust(3)
      puts "#{line_num}│ #{line}".colorize(:light_blue)
    end
    
    if lines.length > 10
      puts "...│ (#{lines.length - 10} more lines)".colorize(:dim)
    end
    
    puts "```"
    puts "📊 Total: #{code.length} characters, #{lines.length} lines".colorize(:dim)
    puts
  end
end
