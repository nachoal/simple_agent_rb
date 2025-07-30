require 'minitest/autorun'
require_relative '../../lib/input/command_processor'
require_relative '../../lib/input/history_manager'

class TestCommandProcessor < Minitest::Test
  def setup
    @test_history_file = '/tmp/test_command_history.json'
    @history_manager = HistoryManager.new(@test_history_file)
    @input_handler = Object.new
    @command_processor = CommandProcessor.new(@input_handler, @history_manager)
    
    # Clean up test files
    File.delete(@test_history_file) if File.exist?(@test_history_file)
    
    # Mock puts and print methods to avoid output during tests
    def @command_processor.puts(*args); end
    def @command_processor.print(*args); end
    def @command_processor.system(*args); true; end
  end

  def teardown
    # Clean up test files
    File.delete(@test_history_file) if File.exist?(@test_history_file)
  end

  def test_returns_original_input_for_non_commands
    result = @command_processor.process_command('regular text')
    assert_equal 'regular text', result
  end

  def test_processes_help_command
    result = @command_processor.process_command('/help')
    assert_equal :continue, result
  end

  def test_processes_clear_command
    result = @command_processor.process_command('/clear')
    assert_equal :continue, result
  end

  def test_processes_history_command
    result = @command_processor.process_command('/history')
    assert_equal :continue, result
  end

  def test_processes_search_command_with_argument
    @history_manager.add_entry('test command to find')
    result = @command_processor.process_command('/search test')
    assert_equal :continue, result
  end

  def test_processes_stats_command
    result = @command_processor.process_command('/stats')
    assert_equal :continue, result
  end

  def test_handles_unknown_commands_gracefully
    result = @command_processor.process_command('/unknown')
    assert_equal :continue, result
  end

  def test_handles_case_insensitive_commands
    result = @command_processor.process_command('/HELP')
    assert_equal :continue, result
  end

  def test_list_commands_returns_sorted_array
    commands = @command_processor.list_commands
    assert_instance_of Array, commands
    assert_includes commands, 'help'
    assert_includes commands, 'history'
    assert_includes commands, 'clear'
    assert_equal commands.sort, commands  # Should be sorted
  end

  def test_help_command_executes_without_error
    assert_silent { @command_processor.send(:cmd_help, '') }
  end

  def test_multiline_command
    # Mock the multiline handler to avoid requiring actual user input
    result = @command_processor.send(:cmd_multiline, '')
    # Should return :continue since we don't have actual input
    assert_equal :continue, result
  end

  def test_code_command_without_language
    result = @command_processor.send(:cmd_code, '')
    assert_equal :continue, result
  end

  def test_code_command_with_language
    result = @command_processor.send(:cmd_code, 'python')
    assert_equal :continue, result
  end

  def test_history_command_with_entries
    # Add test history
    @history_manager.add_entry('first command')
    @history_manager.add_entry('second command')
    @history_manager.add_entry('third command')
    
    result = @command_processor.send(:cmd_history, '')
    assert_equal :continue, result
  end

  def test_search_command_with_valid_term
    @history_manager.add_entry('first command')
    result = @command_processor.send(:cmd_search, 'first')
    assert_equal :continue, result
  end

  def test_search_command_with_empty_term
    result = @command_processor.send(:cmd_search, '')
    assert_equal :continue, result
  end

  def test_stats_command
    @history_manager.add_entry('test command')
    result = @command_processor.send(:cmd_stats, '')
    assert_equal :continue, result
  end

  def test_export_command_default_format
    @history_manager.add_entry('exportable command')
    
    # Mock file writing
    File.stub :write, nil do
      result = @command_processor.send(:cmd_export, '')
      assert_equal :continue, result
    end
  end

  def test_export_command_specified_format
    @history_manager.add_entry('exportable command')
    
    # Mock file writing
    File.stub :write, nil do
      result = @command_processor.send(:cmd_export, 'csv')
      assert_equal :continue, result
    end
  end

  def test_export_command_invalid_format
    result = @command_processor.send(:cmd_export, 'invalid')
    assert_equal :continue, result
  end

  def test_export_handles_errors_gracefully
    @history_manager.add_entry('exportable command')
    
    # Mock file write failure
    File.stub :write, -> { raise StandardError.new('Write failed') } do
      result = @command_processor.send(:cmd_export, 'json')
      assert_equal :continue, result
    end
  end

  def test_exit_command_raises_system_exit
    assert_raises(SystemExit) { @command_processor.send(:cmd_exit, '') }
  end

  def test_handles_commands_with_extra_whitespace
    result = @command_processor.process_command('/  help  ')
    assert_equal :continue, result
  end

  def test_handles_empty_command_arguments
    result = @command_processor.process_command('/history ')
    assert_equal :continue, result
  end

  def test_handles_commands_without_history_manager
    processor_without_history = CommandProcessor.new(@input_handler, nil)
    def processor_without_history.puts(*args); end
    
    result = processor_without_history.send(:cmd_history, '')
    assert_equal :continue, result
  end
end
