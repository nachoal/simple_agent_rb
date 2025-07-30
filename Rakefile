require 'rake/testtask'

# Default task
task default: :test

# Test task
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*test*.rb']
  t.verbose = true
end

# Specific test for input system
Rake::TestTask.new(:test_input) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/input/test*.rb']
  t.verbose = true
end

# Performance test task
task :test_performance do
  puts "Running performance tests..."
  ruby 'test/input/test_integration.rb -n test_large_history_performance'
  ruby 'test/input/test_integration.rb -n test_input_validation_performance'
  puts "Performance tests completed."
end

# Demo task to show the enhanced input system
task :demo do
  puts "Starting enhanced input system demo..."
  puts "Run: ruby bin/main.rb"
  puts "Try these commands:"
  puts "  /help"
  puts "  /multiline"
  puts "  /history"
  puts "  /search <term>"
  puts "  /clear"
end

# Clean task
task :clean do
  FileUtils.rm_f(Dir.glob('/tmp/test_*.json'))
  puts "Cleaned up test files."
end

desc "Show available tasks"
task :help do
  puts "Available tasks:"
  puts "  rake test          - Run all tests"
  puts "  rake test_input    - Run input system tests only"
  puts "  rake test_performance - Run performance tests"
  puts "  rake demo          - Show demo instructions"
  puts "  rake clean         - Clean up test files"
end
