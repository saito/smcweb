class SmcForm
  # require 'yaml/encoding'

  def initialize(fields)
    @fields = fields
    @field_names = @fields.map {|f| f.name }
    @values = {}
  end
  
  def params=(params)
    @values = {}
    params.each do |k,v|
      next if k !~ /^field_(.+)$/ || ! @field_names.include?($1)
      k = $1
      @values[k] = v
    end
  end
  
  def values=(values)
    @values = values
  end
  
  def to_yaml
    hash = {}
    strings = []
    arrays = []
    
    @values.keys.each do |k|
      if k == "body"
        strings[0] = @values[k]
      elsif k =~ /^strings_(\d+)$/
        strings[$1.to_i] = @values[k]
      elsif k =~ /^arrays_(\d+)$/
        arrays[$1.to_i] = @values[k]
      else
        hash[k] = @values[k]
      end
    end
    
    yaml = hash.to_yaml
    yaml = yaml.gsub(/^--- \n/, "")

    strings.each do |str|
      yaml += "--- |\n"
      yaml += str
      if str !~ /\n$/
        yaml += "\n"
      end
    end

    return yaml
  end
  
  def method_missing(name, *args)
    unless name.to_s =~ /^field_(.+)$/
      raise NameError.new("undefined method `#{name}' for SmcForm")
    end
  
    field_name = $1
    setter = false
    if field_name =~ /=$/
      field_name = field_name[0...-1]
      setter = true
    end
    return nil unless @field_names.include? field_name
    
    if setter
      return @values[field_name.to_s] = args[0]
    else
      return @values[field_name.to_s]
    end
  end
end