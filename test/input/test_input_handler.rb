require 'minitest/autorun'
require_relative '../../lib/input/input_handler'

class TestInputHandler < Minitest::Test
  def setup
    @test_history_file = '/tmp/test_agent_history.json'
    @input_handler = InputHandler.new(history_file: @test_history_file)
    
    # Clean up test files
    File.delete(@test_history_file) if File.exist?(@test_history_file)
  end

  def teardown
    # Clean up test files
    File.delete(@test_history_file) if File.exist?(@test_history_file)
  end

  def test_initialize_with_default_settings
    handler = InputHandler.new
    assert_instance_of InputHandler, handler
  end

  def test_initialize_with_custom_history_file
    handler = InputHandler.new(history_file: @test_history_file)
    assert_instance_of InputHandler, handler
  end

  def test_initialize_with_disabled_history
    handler = InputHandler.new(enable_history: false)
    assert_instance_of InputHandler, handler
  end

  def test_simple_input_creation
    # Test the simplified input approach
    assert_silent do
      @input_handler.send(:setup_resize_handler)
    end
  end

  def test_fallback_behavior
    # Test that the class can be instantiated even with potential TTY issues
    assert_instance_of InputHandler, @input_handler
  end
end
