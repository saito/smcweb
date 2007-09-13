class SmcForm
  # require 'yaml/encoding'

  def initialize(fields, params = nil)
    @fields = fields
    if params.nil? 
      @params = default_values
    else
      params = params.reject{|k,v| k !~ /^field_(.+)$/ || fields[$1].nil? }
      @params = {}
      params.each do |k,v|
        k = k.gsub(/^field_/, "")
        @params[k] = v
      end
    end
  end
  
  def default_values
    result = {}
    @fields.keys.each do |k|
        result[k] = @fields[k].value unless @fields[k].value.nil?
    end
    return result
  end
  private :default_values
  
  def to_yaml
    docs = []
    hash = {}
    
    @params.keys.each do |k|
      next if k == "body"
      hash[k] = @params[k]
    end
    docs << hash
    unless @params["body"].nil?
      docs << @params["body"]
    end
    
    yaml = hash.to_yaml
    yaml = yaml.gsub(/^--- \n/, "")

    yaml += "--- |\n"
    yaml += @params["body"]
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
  
    if @fields[field_name.to_s].nil?
      return nil
    end
    
    if setter
      return @params[field_name.to_s] = args[0]
    else
      return @params[field_name.to_s]
    end
  end
end