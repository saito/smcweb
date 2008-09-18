module Smcweb
  class JoinPath < BasePath
    def initialize(conf, override = {})
      @root = conf["root"]
      pconf = {}
      if conf["path"].is_a?(String)
        pconf = parse_string_path_config(conf["path"])
      else
        pconf = conf["path"]
      end
      
      @target_root_uri = pconf["root"]
      @target_root = @root + ("." + pconf["root"])
      @prefix = pconf["prefix"] || ""
      @suffix = pconf["suffix"] || ""
      @pattern = pconf["pattern"] || ".+"
      @init = pconf["init"]
    end
  
    def new_path
      path = @target_root + (@prefix + @init + @suffix)
      
      i = 0
      while path.exist?
        i += 1
        path = @target_root + (@prefix + @init + i.to_s + @suffix)
      end
      
      return path
    end
    
    def list
      result = []
      Dir.chdir(@target_root) do
        Dir.glob("**/*").each do |f|
          if f =~ /#{@pattern}/
            path = @target_root + f
            result << path if path.file?
          end
        end
      end
    
      return result
    end
    
    def args_to_path(args)
      return nil if args.to_a.empty?
      fname = @prefix + args.join("/") + @suffix
      if fname =~ %r{(?:^|/)\.\.?(?:/|$)}
        return nil
      end
      
      return @target_root + fname
    end
  
    def path_to_args(path)
      path = path.to_s
      if path =~ %r{(?:^|/)\.\.?(?:/|$)}
        return nil
      end
      
      rootstr = @target_root.realpath.to_s
      if path.index(rootstr) != 0
        return nil
      end
      path = path[rootstr.length .. -1]
      
      match = path.match(/#{@pattern}/)
      return nil unless match
      result = match.to_a
      result.shift

      return result
    end
  
  end
end