require 'minitest/autorun'
require_relative '../../lib/input/history_manager'

class TestHistoryManager < Minitest::Test
  def setup
    @test_history_file = '/tmp/test_history.json'
    @history_manager = HistoryManager.new(@test_history_file)
    
    # Clean up test files
    File.delete(@test_history_file) if File.exist?(@test_history_file)
  end

  def teardown
    # Clean up test files
    File.delete(@test_history_file) if File.exist?(@test_history_file)
  end

  def test_initialize_with_custom_file
    assert_instance_of HistoryManager, @history_manager
  end

  def test_initialize_with_default_file
    manager = HistoryManager.new
    assert_instance_of HistoryManager, manager
  end

  def test_add_entry
    @history_manager.add_entry('test command')
    recent = @history_manager.get_recent(1)
    assert_includes recent, 'test command'
  end

  def test_ignores_empty_entries
    @history_manager.add_entry('')
    @history_manager.add_entry('   ')
    recent = @history_manager.get_recent(5)
    assert_empty recent
  end

  def test_avoids_consecutive_duplicates
    @history_manager.add_entry('duplicate')
    @history_manager.add_entry('duplicate')
    recent = @history_manager.get_recent(5)
    assert_equal 1, recent.count('duplicate')
  end

  def test_limits_history_size
    # Add more than the max size
    (HistoryManager::MAX_HISTORY_SIZE + 10).times do |i|
      @history_manager.add_entry("command #{i}")
    end
    
    stats = @history_manager.get_stats
    assert_equal HistoryManager::MAX_HISTORY_SIZE, stats[:total_entries]
  end

  def test_search_finds_matching_entries
    @history_manager.add_entry('find this text')
    @history_manager.add_entry('search for something')
    @history_manager.add_entry('another command')
    
    result = @history_manager.search('find')
    assert_equal 'find this text', result
  end

  def test_search_case_insensitive
    @history_manager.add_entry('find this text')
    
    result = @history_manager.search('FIND')
    assert_equal 'find this text', result
  end

  def test_search_returns_nil_for_no_matches
    @history_manager.add_entry('some text')
    
    result = @history_manager.search('nonexistent')
    assert_nil result
  end

  def test_get_recent_entries
    5.times { |i| @history_manager.add_entry("command #{i}") }
    
    recent = @history_manager.get_recent(3)
    assert_equal 3, recent.length
    assert_equal 'command 4', recent.last
  end

  def test_get_recent_with_more_than_available
    5.times { |i| @history_manager.add_entry("command #{i}") }
    
    recent = @history_manager.get_recent(10)
    assert_equal 5, recent.length
  end

  def test_export_to_json
    @history_manager.add_entry('first command')
    @history_manager.add_entry('second command')
    
    json_export = @history_manager.export_history(:json)
    assert_includes json_export, 'first command'
    assert_includes json_export, 'second command'
    
    # Should be valid JSON
    assert_silent { JSON.parse(json_export) }
  end

  def test_export_to_text
    @history_manager.add_entry('first command')
    @history_manager.add_entry('second command')
    
    text_export = @history_manager.export_history(:text)
    assert_includes text_export, 'first command'
    assert_includes text_export, 'second command'
    assert_includes text_export, ':'  # timestamp separator
  end

  def test_export_to_csv
    @history_manager.add_entry('first command')
    @history_manager.add_entry('second command')
    
    csv_export = @history_manager.export_history(:csv)
    assert_includes csv_export, 'timestamp,session_id,content'
    assert_includes csv_export, 'first command'
    assert_includes csv_export, 'second command'
  end

  def test_get_stats
    3.times { |i| @history_manager.add_entry("command #{i}") }
    
    stats = @history_manager.get_stats
    assert_equal 3, stats[:total_entries]
    assert_equal 3, stats[:current_session_entries]
    assert_instance_of Integer, stats[:oldest_entry]
    assert_instance_of Integer, stats[:newest_entry]
  end

  def test_clear_history
    5.times { |i| @history_manager.add_entry("command #{i}") }
    
    @history_manager.clear_history
    stats = @history_manager.get_stats
    assert_equal 0, stats[:total_entries]
  end

  def test_persistence
    # Add entries and save
    @history_manager.add_entry('persistent command')
    
    # Create new manager with same file
    new_manager = HistoryManager.new(@test_history_file)
    recent = new_manager.get_recent(1)
    
    assert_includes recent, 'persistent command'
  end

  def test_handles_corrupted_history_files
    # Write invalid JSON to history file
    File.write(@test_history_file, 'invalid json')
    
    # Should not raise error
    assert_silent { HistoryManager.new(@test_history_file) }
  end
end
