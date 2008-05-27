module Smcweb
  class FixPath < BasePath
    def initialize(config)
      @root = config["root"]
      
      if config["path"].is_a? String
        @path = @root + "." + config["path"]
      else
        @path = @root + "." + config["path"]["root"]
      end
    end
  
    def new_path
      return @path
    end
    
    def list
      return [@path]
    end
    
    def args_to_path(args)
      return @path
    end
  
    def path_to_args(path)
      return []
    end
  
  end
end