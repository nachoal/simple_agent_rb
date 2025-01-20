require_relative "tool"
require_relative "tool_metadata"

class CalculateTool < Tool
  extend ToolMetadata

  describe :call, "Evaluates mathematical expressions with support for basic operators (+, -, *, /, %, **) and parentheses."

  def initialize
    super("calculate")
  end

  def call(expression)
    # Remove any whitespace and validate the expression
    cleaned = expression.gsub(/\s+/, "")
    unless valid_expression?(cleaned)
      return "Invalid expression. Only numbers and basic operators (+, -, *, /, %, **, (, )) are allowed."
    end

    begin
      # Convert the expression to tokens and evaluate
      tokens = tokenize(cleaned)
      evaluate(tokens)
    rescue => e
      "Error calculating expression: #{e.message}"
    end
  end

  private

  def valid_expression?(expr)
    # Only allow numbers, basic operators, and parentheses
    expr.match?(/^[0-9+\-*\/%.()]+$/) && balanced_parentheses?(expr)
  end

  def balanced_parentheses?(expr)
    count = 0
    expr.each_char do |char|
      count += 1 if char == "("
      count -= 1 if char == ")"
      return false if count < 0
    end
    count == 0
  end

  def tokenize(expr)
    tokens = []
    current_number = ""

    expr.each_char do |char|
      if char.match?(/[0-9.]/)
        current_number += char
      else
        tokens << current_number.to_f unless current_number.empty?
        current_number = ""
        tokens << char
      end
    end

    tokens << current_number.to_f unless current_number.empty?
    tokens
  end

  def evaluate(tokens)
    operators = {
      "+" => ->(a, b) { a + b },
      "-" => ->(a, b) { a - b },
      "*" => ->(a, b) { a * b },
      "/" => ->(a, b) { b.zero? ? raise("Division by zero") : a / b },
      "%" => ->(a, b) { a % b },
      "**" => ->(a, b) { a ** b }
    }

    stack = []
    operator_stack = []

    tokens.each do |token|
      case token
      when Numeric
        stack.push(token)
      when String
        if operators.key?(token)
          while operator_stack.any? && precedence(operator_stack.last) >= precedence(token)
            apply_operator(stack, operators[operator_stack.pop])
          end
          operator_stack.push(token)
        end
      end
    end

    while operator_stack.any?
      apply_operator(stack, operators[operator_stack.pop])
    end

    stack.first
  end

  def precedence(operator)
    case operator
    when "**" then 3
    when "*", "/", "%" then 2
    when "+", "-" then 1
    else 0
    end
  end

  def apply_operator(stack, operation)
    b = stack.pop
    a = stack.pop
    stack.push(operation.call(a, b))
  end
end 