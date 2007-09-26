class EditorController < ApplicationController

  before_filter :read_config_filter
  attr_reader :config
  layout "default"
  
  require 'pp'
  require 'smallcage'

  def index
    @files = get_files
    @target_file = get_target_file(true)
    @target_file ||= new_target_file
    @target = relpath(@target_file)
    
    init_fields
    init_form
    render :action => :index
  end
  
  def save
    @files = get_files
    @target_file = get_target_file(false)
    if @target_file.nil?
      render :text => "ERROR: Illegal file name."
    end
    @target = relpath(@target_file)
    
    init_fields
    init_form(params)

    yaml = @form.to_yaml
    File.open(@target_file, "w") do |io|
      io << yaml
    end
    
    publish(@target_file)

    @files = get_files
    render :action => :index
  end

  def delete
    f = get_target_file(true)
    unless f.nil?
      exec_delete(f)
      publish(nil)
    end
    params["target"] = nil
    index    
  end
  
  
private  

  def publish(target_file)
    path = @config["publish"]
    if path.nil?
      exec_publish(target_file)
    else
      publish_config_path(path, target_file)
    end
  end
  
  def publish_config_path(path, target_file)
    if path.is_a?(Array)
      path.each do |p|
        publish_config_path(p, target_file)
      end
      return
    elsif path == :self
      exec_publish(target_file)
      return
    end
    
    unless path.is_a?(String)
      raise "Path is not a String:" + path.to_s
    end

    raise "Illegal publish path:" + path unless path[0] == ?/ || path =~ %r{/\.\./}
    file = @config["root"].join("." + path)
    raise "Illegal publish path:" + path unless file.exist?
    
    exec_publish(file)
  end

  def exec_publish(target_file)
    return if target_file.nil?
    runner = SmallCage::Runner.new({:path => target_file })
    runner.update
  end


  def exec_delete(file)
    File.delete(file)
    
    if file.to_s =~ /.smc/
      out_file = file.to_s[0...-4]
      File.delete(out_file)
    end
  end

  def init_fields
    if ! form_config.nil?
      @fields = SmcField.create_from_config(form_config)
    elsif ! target_obj.nil?
      @fields = SmcField.create_from_sample(target_obj)
    elsif ! sample_obj.nil?
      @fields = SmcField.create_from_sample(sample_obj)
    end
  end
  
  def init_form(params = nil)
    @form = SmcForm.new(@fields)
    if ! params.nil?
      @form.params = params["form"]
    elsif ! target_obj.nil?
      @form.values = target_obj
    elsif ! form_config.nil?
      values = {}
      form_config.each do |c|
        values[c["name"]] = c["value"]
      end
      @form.values = values
    elsif ! sample_obj.nil?
      @form.values = { "template" => sample_obj["template"] }
    end
    
    if @form.field_template.nil?
      @form.field_template = "default"
    end
  end

  def new_target_file
    @filename_retry = 0
    filename_template = Pathname.new(config["config_dir"]).join("filenames/" + config["file_out"] + ".rhtml")
    erb = ERB.new(filename_template.read)
    return format_new_target_file(erb)
  end  

  def format_new_target_file(erb)
    name = erb.result(binding)
    target = config["source_dir"].join(name)
    return target unless target.exist?
    @filename_retry += 1
    if ! config["filename_retry"].nil? || config["filename_retry"].to_i < @filename_retry
      return target
    end
    return format_new_target_file(erb)
  end

  def get_target_file(only_exists = false)
    name = params["target"]
    return nil if name.nil?
    return nil unless valid_file_name?(name)
    result = config["source_dir"].join(name)
    if result.exist? && ! result.file?
      raise "Target already exists, but not a file.: " + name
    elsif only_exists
      return nil unless result.file?
    end
    return result
  end
  
  def target_obj
    if @target_obj.nil?
      return nil unless @target_file.exist?
      @target_obj = load_yaml_as_hash(@target_file)
    end
    return @target_obj
  end

  def sample_obj
    if @sample_obj.nil?
      return nil if @files.size <= 0
      sample_file = @files[0]
      @sample_obj = load_yaml_as_hash(sample_file)
    end
    return @sample_obj
  end

  def form_config
    if @form_config.nil?
      @form_config = load_form_config
    end
    return @form_config
  end

  def load_form_config
    name = config["form"]
    return nil if name.nil?
    file = Pathname.new(config["config_dir"]).join("forms/" + name + ".yml")
    raise "form config file not exists: " + file.to_s unless file.file?
   
    config = YAML.load(File.read(file))
    raise "form config must be array: " + file.to_s unless config.is_a?(Array)

    return config
  end  

  def valid_file_name?(name)
    return name =~ config["file_in"]
  end
  
  def get_files
    dir = config["source_dir"]
    result = []
    Pathname.glob(dir.to_s + "/**/*") do |path|
      rp = relpath(path)
      next if rp.nil?
      next unless valid_file_name?(rp.to_s)
      result << path
    end
    return result.sort {|a,b| a.to_s <=> b.to_s }
  end

end
