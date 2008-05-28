class SmcForm
  # require 'yaml/encoding'
  attr_accessor :values, :path_args

  def initialize(fields)
    @fields = fields
    @fields_hash = {}
    @path_fields = []
    @fields.each do |f|
      if f.path?
        @path_fields[f.path_index] = f
      else
        @fields_hash[f.name] = f
      end
    end
    @values = {}
    @path_args = []
  end
  
  def params=(params)
    @values = {}
    params.each do |k,v|
      if k =~ /^field_(.+)$/ && @fields_hash.key?($1)
        k = $1
        if @fields_hash[k].field_type == "array"
          @values[k] = v.split(/\r\n|\r|\n/)
        else
          @values[k] = v
        end
      elsif k =~ /^path_(\d+)$/ && ! @path_fields[$1.to_i].nil?
        k = $1
        @path_args[k.to_i] = v
      end
    end
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
    name = name.to_s
    setter = name.ends_with?("=")
    name = name[0...-1] if setter

    if name.to_s =~ /^field_(.+)$/
      name = $1
      if setter
        return set_field_value_from_form(name, args[0])
      else
        return get_field_value_for_form(name)
      end
    elsif name.to_s =~ /^path_(\d+)$/
      index = $1.to_i
      if setter
        return set_path_arg_from_form(index, args[0])
      else
        return @path_args[index]
      end
    else
      raise NameError.new("undefined method `#{name}' for SmcForm")
    end
  end

  
  def set_field_value_from_form(name, value)
    field = @fields_hash[name]
    return nil if field.nil?
    if value.nil?
      return @values[name] = nil
    end
    if field.field_type == "array"
      return @values[name] = value.split(/\r\n|\r|\n/)
    else
      return @values[name] = value
    end
  end
  private :set_field_value_from_form
  
  def get_field_value_for_form(name)
    field = @fields_hash[name]
    return nil if field.nil?
    if field.field_type == "array"
      return nil if @values[name].nil?
      return @values[name].join("\n")
    else
      return @values[name]
    end
  end
  private :get_field_value_for_form
  
  def set_path_arg_from_form(index, value)
    field = @path_fields[index]
    return nil if field.nil?
    @path_args[index] = value
  end
  private :set_path_arg_from_form
  
end
