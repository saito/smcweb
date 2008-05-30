module Smcweb
  class DatePath < BasePath
    FNAME_FORMAT = {
      4 => "%Y",
      6 => "%Y%m",
      8 => "%Y%m%d",
      10 => "%Y%m%d%H",
      12 => "%Y%m%d%H%M",
      14 => "%Y%m%d%H%M%S",
    }
    
    ARG_FORMAT = {
      4 => "%Y",
      6 => "%Y-%m",
      8 => "%Y-%m-%d",
      10 => "%Y-%m-%d %H:00",
      12 => "%Y-%m-%d %H:%M",
      14 => "%Y-%m-%d %H:%M:%S",
    }
    
    INCREMENT = {
      4 => "year",
      6 => "month",
      8 => "day",
      10 => "hour",
      12 => "min",
      14 => "sec",
    }
  
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
          @length = 14
        else
          @length = pconf["length"].to_i
        end
      end
        
      @fname_format = pconf["fname_format"] || FNAME_FORMAT[@length]
      @arg_format = pconf["arg_format"] || ARG_FORMAT[@length]
      @increment = pconf["increment"] || INCREMENT[@length]
      
      if @length < 0 || @fname_format.nil? || @arg_format.nil? || @increment.nil?
        throw Exception.new("Illegal DatePath argument")
      end

    end
    
    def new_path
      return _new_path(DateTime.now)
    end
    
    def _new_path(t)
      fname = @prefix + t.strftime(@fname_format) + @suffix
      path = @target_root + fname
      return path unless path.exist?

      if @increment == "year"
        t = t >> 12
      elsif @increment == "month"
        t = t >> 1
      elsif @increment == "day"
        t = t + 1
      elsif @increment == "hour"
        t = t + Rational(1, 24)
      elsif @increment == "min"
        t = t + Rational(1, 24 * 60)
      elsif @increment == "sec"
        t = t + Rational(1, 24 * 60 * 60)
      end

      return _new_path(t)
    end
    private :_new_path
    
    def fname_to_date(fname)
      return nil unless fname.starts_with?(@prefix)
      return nil unless fname.ends_with?(@suffix)
      
      date = fname[@prefix.length .. @suffix.length * -1 - 1]

      # need to check length.
      # strptime ignore the trailing characters.
      return nil if date.length != @length

      begin
        return DateTime.strptime(date, @fname_format)
      rescue
        return nil
      end
    end
    private :fname_to_date
    
    def arg_to_date(arg)
      begin
        return DateTime.strptime(arg, @arg_format)
      rescue
        return nil
      end
    end
    private :arg_to_date
    
    def list
      result = []
      Dir.foreach(@target_root) do |fname|
        date = fname_to_date(fname)
        unless date.nil?
          result << @target_root + fname
        end
      end
      return result.sort
    end
    
    def args_to_path(args)
      date = arg_to_date(args[0])
      return nil if date.nil?
      fname = @prefix + date.strftime(@fname_format) + @suffix
      return @target_root + fname
    end
  
    def path_to_args(path)
      begin
        return nil unless @target_root.realpath == path.parent.realpath
      rescue
        return nil
      end
      
      fname = path.basename.to_s
      date = fname_to_date(fname)
      return nil if date.nil?
    
      return [date.strftime(@arg_format)]
    end
    
  end
end