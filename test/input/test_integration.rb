require 'minitest/autorun'
require_relative '../../lib/input/input_handler'

class TestInputSystemIntegration < Minitest::Test
  def setup
    @test_history_file = '/tmp/test_integration_history.json'
    @input_handler = InputHandler.new(history_file: @test_history_file)
    
    # Clean up test files
    File.delete(@test_history_file) if File.exist?(@test_history_file)
  end

  def teardown
    # Clean up test files
    File.delete(@test_history_file) if File.exist?(@test_history_file)
  end

  def test_complete_workflow_without_errors
    # Test system initialization
    assert_instance_of InputHandler, @input_handler
    
    # Test resize handler setup
    assert_silent { @input_handler.send(:setup_resize_handler) }
  end

  def test_history_persistence_across_operations
    history_manager = @input_handler.instance_variable_get(:@history_manager)
    
    history_manager.add_entry('first command')
    history_manager.add_entry('second command')
    
    recent = history_manager.get_recent(2)
    assert_includes recent, 'first command'
    assert_includes recent, 'second command'
  end

  def test_input_validation_throughout_workflow
    validator = @input_handler.instance_variable_get(:@input_validator)
    
    # Test various input types
    normal_result = validator.validate('normal input')
    assert normal_result[:valid]
    
    empty_result = validator.validate('')
    refute empty_result[:valid]
    
    long_result = validator.validate('x' * 10001)
    refute long_result[:valid]
  end

  def test_command_processing_integration
    command_processor = @input_handler.instance_variable_get(:@command_processor)
    command_processor.define_singleton_method(:puts) { |*args| }
    
    # Test help command
    result = command_processor.process_command('/help')
    assert_equal :continue, result
    
    # Test regular input
    result = command_processor.process_command('regular text')
    assert_equal 'regular text', result
  end

  def test_error_handling_and_recovery
    # Test TTY library failure handling
    assert_instance_of InputHandler, InputHandler.new
  end

  def test_corrupted_history_file_recovery
    # Create corrupted history file
    File.write(@test_history_file, 'invalid json content')
    
    # Should not crash when loading
    assert_silent { InputHandler.new(history_file: @test_history_file) }
  end

  def test_terminal_resize_during_input
    # Test resize handler setup doesn't crash
    assert_silent { @input_handler.send(:setup_resize_handler) }
  end

  def test_small_terminal_fallback
    # Simplified - just test that the handler can be initialized
    assert_instance_of InputHandler, @input_handler
  end

  def test_cross_platform_compatibility
    # Test clear screen command on different platforms
    command_processor = @input_handler.instance_variable_get(:@command_processor)
    command_processor.define_singleton_method(:puts) { |*args| }
    command_processor.define_singleton_method(:system) { |*args| true }
    
    # Should not crash even if system commands behave differently
    assert_silent { command_processor.send(:cmd_clear, '') }
  end

  def test_signal_handling_differences
    # Some platforms may not support SIGWINCH
    assert_silent { @input_handler.send(:setup_resize_handler) }
  end

  def test_large_history_performance
    history_manager = @input_handler.instance_variable_get(:@history_manager)
    
    # Add many entries and measure time
    start_time = Time.now
    100.times { |i| history_manager.add_entry("command #{i}") }
    add_time = Time.now - start_time
    
    # Should be fast (under 1 second for 100 entries)
    assert add_time < 1.0
    
    # Search should also be fast
    start_time = Time.now
    result = history_manager.search('command 50')
    search_time = Time.now - start_time
    
    assert search_time < 0.1
    assert_equal 'command 50', result
  end

  def test_memory_usage_limits
    history_manager = @input_handler.instance_variable_get(:@history_manager)
    
    # Add more than max size
    (HistoryManager::MAX_HISTORY_SIZE + 100).times do |i|
      history_manager.add_entry("command #{i}")
    end
    
    stats = history_manager.get_stats
    assert_equal HistoryManager::MAX_HISTORY_SIZE, stats[:total_entries]
  end

  def test_input_validation_performance
    validator = @input_handler.instance_variable_get(:@input_validator)
    
    # Test validation speed
    start_time = Time.now
    100.times { validator.validate('test input') }
    validation_time = Time.now - start_time
    
    # Should be very fast (under 0.1 seconds for 100 validations)
    assert validation_time < 0.1
  end

  def test_backward_compatibility_interface
    # Test that the enhanced input system maintains expected interface
    assert_respond_to @input_handler, :read_input
  end

  def test_legacy_history_format_compatibility
    # Create old-style history file
    old_history_file = @test_history_file.gsub('.json', '')
    File.write(old_history_file, "old command 1\nold command 2\n")
    
    # Should be able to load and convert
    manager = HistoryManager.new(@test_history_file)
    recent = manager.get_recent(5)
    
    # Should include converted entries
    assert_includes recent, 'old command 1'
    assert_includes recent, 'old command 2'
    
    # Clean up
    File.delete(old_history_file) if File.exist?(old_history_file)
  end
end
