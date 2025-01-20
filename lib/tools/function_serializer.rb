def function_to_json(method_obj)
  # A rough Ruby equivalent to the Python function that converts a method's signature
  # into a hash describing name, parameters, and (optionally) docstring.
  #
  # Note: Ruby does not provide a straightforward way to retrieve a method's docstring.
  #       You might maintain method documentation separately or use a doc extraction gem.
  #       For parameter type inference, we also rely on basic Ruby class mappings since
  #       Ruby does not enforce static type hints by default.

  type_map = {
    "String"    => "string",
    "Integer"   => "integer",
    "Float"     => "number",
    "TrueClass" => "boolean",
    "FalseClass" => "boolean",
    "Array"     => "array",
    "Hash"      => "object",
    "NilClass"  => "null"
  }

  # Fallback to "string" if we cannot determine a more specific type
  param_type_fallback = "string"

  parameters = {}
  required_params = []

  # Retrieve the docstring if available through ToolMetadata
  klass = method_obj.owner
  docstring = if klass.respond_to?(:description_for)
                klass.description_for(method_obj.name)
              else
                "Documentation not available via reflection."
              end

  method_obj.parameters.each do |param_def|
    # param_def is an array: [:req, :param_name] or [:opt, :param_name], etc.
    # param_type is not strictly known in Ruby without runtime checks,
    # so we map basic param kind first (required, optional, etc.).
    # For demonstration, we assume a fallback "string".
    kind, param_name = param_def

    # Let's assume required if parameter kind is :req or :keyreq
    is_required = (kind == :req || kind == :keyreq)

    # Store the parameter with an assumed type
    parameters[param_name.to_s] = { "type" => param_type_fallback }
    required_params << param_name.to_s if is_required
  end

  {
    "type" => "function",
    "function" => {
      "name" => method_obj.name.to_s,
      "description" => docstring,
      "parameters" => {
        "type" => "object",
        "properties" => parameters,
        "required" => required_params
      }
    }
  }
end