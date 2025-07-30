require 'minitest/autorun'
require 'minitest/pride'  # For colorized output

# Add lib to load path
$LOAD_PATH.unshift(File.join(__dir__, '..', 'lib'))

# Suppress output during tests unless explicitly testing output
class Minitest::Test
  def setup
    super
    @original_stdout = $stdout
    @original_stderr = $stderr
  end

  def teardown
    super
    $stdout = @original_stdout
    $stderr = @original_stderr
  end

  # Helper method to capture output
  def capture_output
    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
    [$stdout.string, $stderr.string]
  ensure
    $stdout = old_stdout
    $stderr = old_stderr
  end

  # Helper method to silence output
  def silence_output
    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
  ensure
    $stdout = old_stdout
    $stderr = old_stderr
  end
end
