class InputValidator
  def initialize
    @validators = {
      length: method(:validate_length),
      not_empty: method(:validate_not_empty),
      no_spam: method(:validate_no_spam),
      safe_content: method(:validate_safe_content)
    }
    @recent_inputs = []
    @last_input_time = nil
  end

  def validate(input, rules = [:not_empty, :length, :no_spam, :safe_content])
    errors = []
    
    rules.each do |rule|
      if @validators.key?(rule)
        error = @validators[rule].call(input)
        errors << error if error
      end
    end
    
    update_input_tracking(input) if errors.empty?
    
    {
      valid: errors.empty?,
      errors: errors,
      warnings: generate_warnings(input)
    }
  end

  def suggest_improvements(input)
    suggestions = []
    
    # Check for very short inputs
    if input.length < 10
      suggestions << "💡 Consider providing more context for better AI responses"
    end
    
    # Check for all caps
    if input == input.upcase && input.length > 20
      suggestions << "💡 Consider using normal capitalization for better readability"
    end
    
    # Check for repeated punctuation
    if input.match?(/[!?]{3,}/)
      suggestions << "💡 Excessive punctuation detected - the AI understands emphasis without it"
    end
    
    # Check for code without formatting
    if looks_like_code?(input) && !input.include?('```')
      suggestions << "💡 Consider using /code command for better code formatting"
    end
    
    # Check for very long single-line input
    if input.length > 200 && !input.include?("\n")
      suggestions << "💡 Consider using /multiline for long inputs to improve readability"
    end
    
    suggestions
  end

  private

  def validate_length(input)
    return "Input is too long (max 10,000 characters)" if input.length > 10_000
    nil
  end

  def validate_not_empty(input)
    return "Input cannot be empty" if input.strip.empty?
    nil
  end

  def validate_no_spam(input)
    # Check for rapid repeated inputs
    if @recent_inputs.include?(input) && time_since_last_input < 2
      return "Please avoid sending duplicate messages too quickly"
    end
    
    # Check for repetitive content
    if input.length > 50 && repetitive_content?(input)
      return "Input appears to contain repetitive content"
    end
    
    nil
  end

  def validate_safe_content(input)
    # Basic checks for potentially harmful content
    dangerous_patterns = [
      /rm\s+-rf\s+\/|rm\s+-rf\s+\*/i,  # Dangerous file deletion
      /format\s+c:|del\s+\*\.\*/i,      # Windows dangerous commands
      /sudo\s+rm|sudo\s+dd/i,          # Dangerous sudo commands
      /<script\s*>/i,                   # Script injection
      /javascript:/i                    # Javascript protocol
    ]
    
    dangerous_patterns.each do |pattern|
      if input.match?(pattern)
        return "Input contains potentially unsafe content"
      end
    end
    
    nil
  end

  def generate_warnings(input)
    warnings = []
    
    # Warn about potential sensitive information
    if contains_potential_secrets?(input)
      warnings << "⚠️  Input may contain sensitive information (API keys, passwords, etc.)"
    end
    
    # Warn about very technical content
    if highly_technical?(input)
      warnings << "💡 Technical content detected - providing more context might help"
    end
    
    warnings
  end

  def update_input_tracking(input)
    @recent_inputs << input
    @recent_inputs = @recent_inputs.last(10)  # Keep only recent inputs
    @last_input_time = Time.now
  end

  def time_since_last_input
    return Float::INFINITY unless @last_input_time
    Time.now - @last_input_time
  end

  def repetitive_content?(input)
    # Check for repeated words or phrases
    words = input.downcase.split(/\s+/)
    return false if words.length < 10
    
    # Check for same word repeated many times
    word_counts = words.each_with_object(Hash.new(0)) { |word, counts| counts[word] += 1 }
    max_count = word_counts.values.max
    
    # If any word appears more than 30% of the time, it's likely repetitive
    max_count > words.length * 0.3
  end

  def looks_like_code?(input)
    code_indicators = [
      /def\s+\w+\(.*\)/,           # Function definitions
      /class\s+\w+/,               # Class definitions
      /import\s+\w+/,              # Import statements
      /require\s+['"][^'"]+['"]/,  # Require statements
      /\w+\.\w+\(/,                # Method calls
      /=>\s*\{/,                   # Arrow functions
      /\$\w+\s*=/,                 # Variable assignments
      /console\.log\(/,            # Console logging
      /println\!/,                 # Rust/other language prints
      /\w+::\w+/                   # Namespace resolution
    ]
    
    code_indicators.any? { |pattern| input.match?(pattern) }
  end

  def contains_potential_secrets?(input)
    secret_patterns = [
      /api[_-]?key/i,
      /secret[_-]?key/i,
      /access[_-]?token/i,
      /password/i,
      /auth[_-]?token/i,
      /bearer\s+[a-zA-Z0-9_-]+/i,
      /sk-[a-zA-Z0-9]+/,           # OpenAI API key pattern
      /ghp_[a-zA-Z0-9]+/,          # GitHub token pattern
      /\b[A-Z0-9]{32,}\b/          # Long alphanumeric strings (potential keys)
    ]
    
    secret_patterns.any? { |pattern| input.match?(pattern) }
  end

  def highly_technical?(input)
    # Check for high density of technical terms
    technical_terms = [
      'algorithm', 'function', 'variable', 'method', 'class', 'object',
      'database', 'query', 'schema', 'table', 'index', 'transaction',
      'server', 'client', 'api', 'endpoint', 'request', 'response',
      'framework', 'library', 'package', 'module', 'component',
      'deployment', 'configuration', 'environment', 'docker', 'kubernetes'
    ]
    
    words = input.downcase.split(/\s+/)
    technical_count = words.count { |word| technical_terms.include?(word.gsub(/[^\w]/, '')) }
    
    # If more than 20% of words are technical terms
    technical_count > words.length * 0.2
  end
end
