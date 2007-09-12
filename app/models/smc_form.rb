class SmcForm
  def initialize(fields, params = nil)
    @fields = fields
    if params.nil? 
      @params = default_values
    else
      @params = params.reject{|k,v| fields[k].nil? }
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
  
  
  def method_missing(name, *args)
    setter = false
    if name =~ /=$/
      field_name = name[0...-1]
      setter = true
    else
      field_name = name
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