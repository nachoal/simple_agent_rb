module ToolMetadata
  def describe(method_name, description)
    @method_descriptions ||= {}
    @method_descriptions[method_name] = description
  end

  def description_for(method_name)
    @method_descriptions && @method_descriptions[method_name]
  end
end 