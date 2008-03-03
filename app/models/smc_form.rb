class SmcForm
  # require 'yaml/encoding'
  attr_accessor :values

  def initialize(fields)
    @fields = fields
    @fields_hash = {}
    @fields.each do |f|
      @fields_hash[f.name] = f
    end
    @values = {}
  end
  
  def params=(params)
    @values = {}
    params.each do |k,v|
      next if k !~ /^field_(.+)$/ || ! @fields_hash.key?($1)
      k = $1
      if @fields_hash[k].typ == "array"
        @values[k] = v.split(/\r\n|\r|\n/)
      else
        @values[k] = v
      end
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

    arrays.each do |arr|
      yaml += "--- |\n"
      
      tmp = arr.to_yaml
      tmp = tmp.gsub(/^--- \n/, "")
      yaml += tmp
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
    return nil unless @fields_hash.key?(field_name)
    
    field = @fields_hash[field_name]
    if setter
      v = args[0]
      if v.nil?
        return @values[field_name] = nil
      end
      if field.typ == "array"
        return @values[field_name] = v.split(/\r\n|\r|\n/)
      else
        return @values[field_name] = v
      end
    else
      if field.typ == "array"
        return nil if @values[field_name].nil?
        return @values[field_name].join("\n")
      else
        return @values[field_name]
      end
    end
  end
end
