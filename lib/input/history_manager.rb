require 'json'

class HistoryManager
  MAX_HISTORY_SIZE = 1000
  
  def initialize(history_file = nil)
    @history_file = history_file || default_history_file
    @history = []
    @history_index = 0
    @search_index = 0
    @search_results = []
    load_history
  end

  def add_entry(input)
    return if input.strip.empty?
    return if @history.last == input  # Avoid consecutive duplicates
    
    @history << {
      content: input,
      timestamp: Time.now.to_i,
      session_id: current_session_id
    }
    
    @history_index = @history.length
    
    # Limit history size
    if @history.length > MAX_HISTORY_SIZE
      @history = @history.last(MAX_HISTORY_SIZE)
      @history_index = @history.length
    end
    
    save_history
  end

  def get_previous
    return nil if @history.empty? || @history_index <= 0
    
    @history_index -= 1
    @history[@history_index][:content]
  end

  def get_next
    return nil if @history.empty? || @history_index >= @history.length - 1
    
    @history_index += 1
    @history[@history_index][:content]
  end

  def search(query)
    @search_results = @history.select do |entry|
      entry[:content].downcase.include?(query.downcase)
    end
    @search_index = 0
    
    @search_results.empty? ? nil : @search_results.first[:content]
  end

  def next_search_result
    return nil if @search_results.empty?
    
    @search_index = (@search_index + 1) % @search_results.length
    @search_results[@search_index][:content]
  end

  def get_recent(count = 10)
    @history.last(count).map { |entry| entry[:content] }
  end

  def get_stats
    {
      total_entries: @history.length,
      current_session_entries: @history.count { |e| e[:session_id] == current_session_id },
      oldest_entry: @history.first&.dig(:timestamp),
      newest_entry: @history.last&.dig(:timestamp)
    }
  end

  def clear_history
    @history.clear
    @history_index = 0
    save_history
  end

  def export_history(format = :json)
    case format
    when :json
      JSON.pretty_generate(@history)
    when :text
      @history.map do |entry|
        time = Time.at(entry[:timestamp]).strftime("%Y-%m-%d %H:%M:%S")
        "#{time}: #{entry[:content]}"
      end.join("\n")
    when :csv
      header = "timestamp,session_id,content\n"
      rows = @history.map do |entry|
        "#{entry[:timestamp]},#{entry[:session_id]},\"#{entry[:content].gsub('"', '""')}\""
      end.join("\n")
      header + rows
    end
  end

  private

  def default_history_file
    File.join(Dir.home, '.simple_agent_history.json')
  end

  def current_session_id
    @session_id ||= Time.now.to_i.to_s
  end

  def load_history
    return unless File.exist?(@history_file)
    
    content = File.read(@history_file)
    @history = JSON.parse(content, symbolize_names: true)
    @history_index = @history.length
  rescue => e
    # If parsing fails, try to load as plain text (legacy format)
    load_legacy_history
  end

  def load_legacy_history
    return unless File.exist?(@history_file.gsub('.json', ''))
    
    legacy_file = @history_file.gsub('.json', '')
    lines = File.readlines(legacy_file, chomp: true)
    
    @history = lines.map do |line|
      {
        content: line,
        timestamp: Time.now.to_i,
        session_id: 'legacy'
      }
    end
    
    @history_index = @history.length
    save_history  # Convert to new format
  rescue => e
    @history = []
    @history_index = 0
  end

  def save_history
    File.write(@history_file, JSON.pretty_generate(@history))
  rescue => e
    # Ignore saving errors
  end
end
