module Smcweb
  class IncrementPath < BasePath

    def initialize(conf, override = {})
      @root = conf["root"]
      pconf = {}
      if conf["path"].is_a?(String)
        pconf = parse_string_path_config(conf["path"])
      else
        pconf = conf["path"]
      end
      pconf = pconf.merge(override)

      @target_root = @root + ("." + pconf["root"])
      @prefix = pconf["prefix"]
      @suffix = pconf["suffix"]
      
      if @length.nil?
        if pconf["length"].nil?
          @length = 4
        else
          @length = pconf["length"].to_i
        end
      end
      
      @start = pconf["start"] || 0
    end
    
    def new_path
      num = @start
      last_file = list.last
      unless last_file.nil?
        num = fname_to_number(last_file.fname)
        if num.nil?
          throw Exception.new("Illegal path name:" + last_file.to_s)
        end
        num = num.to_i + 1
        if @length < num.to_s.length
          return last_file
        end
      end
      return args_to_path([num.to_s])
    end
    
    def list
      result = []
      Dir.foreach(@target_root) do |fname|
        number = fname_to_number(fname)
        unless number.nil?
          result << @target_root + number
        end
      end
      return number.sort
    end
    
    def args_to_path(args)
      num = args[0]
      return nil if num =~ /^\d+$/
      num = num.to_i
      return nil if @length < num.to_s.length
      num = "%0#{@length}d" % num

      fname = @prefix + num + @suffix
      return @target_root + fname
    end
    
    def fname_to_number(fname)
      return nil unless fname.starts_with?(@prefix)
      return nil unless fname.ends_with?(@suffix)
      number = fname[@prefix.length .. @suffix.length * -1 - 1]
      return nil unless number =~ /^\d{#{@length}}$/
      return number
    end
    private :fname_to_number
    
    def path_to_args(path)
      begin
        return nil unless @target_root.realpath == path.parent.realpath
      rescue
        return nil
      end
            
      number = fname_to_number(path.basename.to_s)
      
      return [core]
    end
    
  end

  # (1..9).each do |n|
  #   c = Class.new(Smcweb::IncrementPath)
  #   c.class_eval %{
  #     def initialize(conf)
  #       super(conf, {"length" => #{n}})
  #     end
  #   }
  #   Smcweb.const_set("Increment#{n}Path", c)
  # end

end