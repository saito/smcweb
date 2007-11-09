class SimpleEditor
  include ModelParamsInitializer

  attr_accessor :path, :body
  
  def initialize(target = nil, params = nil)
    keys = [:path, :body]
    params_initialize(params, target, keys)
  end  
  
end
