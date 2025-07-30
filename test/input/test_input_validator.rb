require 'minitest/autorun'
require_relative '../../lib/input/input_validator'

class TestInputValidator < Minitest::Test
  def setup
    @validator = InputValidator.new
  end

  def test_validates_normal_input
    result = @validator.validate('Hello, how are you today?')
    assert result[:valid]
    assert_empty result[:errors]
  end

  def test_rejects_empty_input
    result = @validator.validate('')
    refute result[:valid]
    assert_includes result[:errors], 'Input cannot be empty'
  end

  def test_rejects_whitespace_only_input
    result = @validator.validate('   ')
    refute result[:valid]
    assert_includes result[:errors], 'Input cannot be empty'
  end

  def test_rejects_overly_long_input
    long_input = 'x' * 10001
    result = @validator.validate(long_input)
    refute result[:valid]
    assert_includes result[:errors], 'Input is too long (max 10,000 characters)'
  end

  def test_detects_dangerous_commands
    dangerous_input = 'rm -rf /'
    result = @validator.validate(dangerous_input)
    refute result[:valid]
    assert_includes result[:errors], 'Input contains potentially unsafe content'
  end

  def test_detects_script_injection
    script_input = '<script>alert("test")</script>'
    result = @validator.validate(script_input)
    refute result[:valid]
    assert_includes result[:errors], 'Input contains potentially unsafe content'
  end

  def test_suggests_context_for_short_inputs
    suggestions = @validator.suggest_improvements('hi')
    assert_includes suggestions, '💡 Consider providing more context for better AI responses'
  end

  def test_suggests_normal_capitalization
    suggestions = @validator.suggest_improvements('THIS IS ALL CAPS TEXT THAT IS QUITE LONG')
    assert_includes suggestions, '💡 Consider using normal capitalization for better readability'
  end

  def test_suggests_reducing_excessive_punctuation
    suggestions = @validator.suggest_improvements('What is this???!!!')
    assert_includes suggestions, '💡 Excessive punctuation detected - the AI understands emphasis without it'
  end

  def test_suggests_code_command_for_code
    code_input = 'def hello_world(): print("Hello, world!")'
    suggestions = @validator.suggest_improvements(code_input)
    assert_includes suggestions, '💡 Consider using /code command for better code formatting'
  end

  def test_suggests_multiline_for_long_input
    long_input = 'This is a very long input that goes on and on and should probably be broken into multiple lines for better readability and easier processing by both humans and AI systems.'
    suggestions = @validator.suggest_improvements(long_input)
    assert_includes suggestions, '💡 Consider using /multiline for long inputs to improve readability'
  end

  def test_detects_python_functions
    assert @validator.send(:looks_like_code?, 'def my_function():')
  end

  def test_detects_class_definitions
    assert @validator.send(:looks_like_code?, 'class MyClass:')
  end

  def test_detects_import_statements
    assert @validator.send(:looks_like_code?, 'import os')
  end

  def test_detects_method_calls
    assert @validator.send(:looks_like_code?, 'object.method()')
  end

  def test_detects_require_statements
    assert @validator.send(:looks_like_code?, 'require "json"')
  end

  def test_does_not_detect_regular_text_as_code
    refute @validator.send(:looks_like_code?, 'This is just regular text')
  end

  def test_detects_api_keys
    input = 'My API key is sk-1234567890abcdef'
    assert @validator.send(:contains_potential_secrets?, input)
  end

  def test_detects_password_mentions
    input = 'The password is secret123'
    assert @validator.send(:contains_potential_secrets?, input)
  end

  def test_detects_github_tokens
    input = 'Use this token: ghp_1234567890abcdef'
    assert @validator.send(:contains_potential_secrets?, input)
  end

  def test_detects_bearer_tokens
    input = 'Authorization: Bearer abc123def456'
    assert @validator.send(:contains_potential_secrets?, input)
  end

  def test_does_not_flag_normal_text_as_secrets
    input = 'This is normal text without secrets'
    refute @validator.send(:contains_potential_secrets?, input)
  end

  def test_detects_technical_content
    technical_input = 'The algorithm uses a database query to fetch API endpoints from the server configuration'
    assert @validator.send(:highly_technical?, technical_input)
  end

  def test_does_not_flag_normal_conversation_as_technical
    normal_input = 'How are you doing today? I hope you are well'
    refute @validator.send(:highly_technical?, normal_input)
  end

  def test_detects_repetitive_content
    repetitive = 'test ' * 50
    assert @validator.send(:repetitive_content?, repetitive)
  end

  def test_does_not_flag_normal_content_as_repetitive
    normal = 'This is a normal sentence with varied words and concepts'
    refute @validator.send(:repetitive_content?, normal)
  end

  def test_prevents_rapid_duplicate_submissions
    # Simulate rapid input
    @validator.instance_variable_set(:@last_input_time, Time.now - 1)
    @validator.instance_variable_set(:@recent_inputs, ['duplicate message'])
    
    result = @validator.validate('duplicate message')
    refute result[:valid]
    assert_includes result[:errors], 'Please avoid sending duplicate messages too quickly'
  end

  def test_warns_about_sensitive_information
    input = 'My API key is secret123'
    result = @validator.validate(input, [:not_empty, :length])  # Skip safe_content check
    assert_includes result[:warnings], '⚠️  Input may contain sensitive information (API keys, passwords, etc.)'
  end

  def test_warns_about_technical_content
    technical_input = 'Configure the database schema with API endpoints and server deployment using Docker containers'
    result = @validator.validate(technical_input, [:not_empty, :length])
    assert_includes result[:warnings], '💡 Technical content detected - providing more context might help'
  end
end
