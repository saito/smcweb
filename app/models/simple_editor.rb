class SimpleEditor
  include ModelParamsInitializer

  attr_accessor :body, :file_name
  
  def initialize(params = nil, target = nil)
    keys = [:body, :file_name]
    params_initialize(params, target, keys)
  end
  
end
