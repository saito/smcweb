class SmcField
  attr_accessor :name, :field_type, :options, :label, :path_index

  def initialize(name_or_path_index, field_type, label = nil, options = nil)
    if name_or_path_index.is_a? String
      @name = name_or_path_index
    else
      @path_index = name_or_path_index.to_i
      @name = name_or_path_index.to_s
    end
    @field_type = field_type
    @label = label
    @options = options
    @label ||= name.capitalize
  end
  
  # name using HTML Form
  def html_input_name
    if path?
      return "path_" + @name
    else
      return "field_" + @name
    end
  end
  
  def path?
    return ! @path_index.nil?
  end

  def self.create_from_sample(sample)
    result = []
    sample.keys.each do |k|
      if k == "body" || k =~ /^strings_\d+$/
        result << SmcField.new(k, "textarea")
      elsif k =~ /^arrays_\d+$/
        result << SmcField.new(k, "array")
      else
        result << SmcField.new(k, "text")
      end
    end
    
    # TODO path args
    
    return result    
  end

  def self.create_from_config(form_config)
    result = []
    form_config.each do |c|
      keys = %w(name type label value)
      opts = c.reject {|k, v| keys.include?(k)}
      if c["path"].to_s =~ /^\d+$/
        name_or_path_index = c["path"].to_i
      else
        name_or_path_index = c["name"]
      end
      
      result << SmcField.new(name_or_path_index, c["type"], c["label"], opts)
    end
    return result
  end

end