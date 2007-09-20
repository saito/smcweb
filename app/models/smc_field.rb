class SmcField
  attr_accessor :name, :typ, :options, :label

  def initialize(name, typ, label = nil, options = nil)
    @name = name
    @typ = typ
    @label = label
    @options = options
    
    @label ||= name.capitalize
  end

  def self.create_from_sample(sample)
    result = []
    sample.keys.each do |k|
      if k == "body" || k =~ /^strings_\d+$/
        result << SmcField.new(k, "text")
      elsif k =~ /^arrays_\d+$/
        result << SmcField.new(k, "array")
      else
        result << SmcField.new(k, "text")
      end
    end
    
    return result    
  end

  def self.create_from_config(form_config)
    result = []
    form_config.each do |c|
      keys = %w(name type label value)
      opts = c.reject {|k, v| keys.include?(k)}
      result << SmcField.new(c["name"], c["type"], c["label"], opts)
    end
    return result
  end

end