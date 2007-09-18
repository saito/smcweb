class EditorController < ApplicationController

  before_filter :read_config_filter
  attr_reader :config
  layout "default"
  
  require 'pp'
  require 'smallcage'

  def index
    @files = get_files
    
    init_fields
    init_form
    
    target = relpath(get_target_file(true))
    if target.nil?
      target = relpath(new_target_file)
    end
    @target = target
  end
  
  def save
    @files = get_files

    init_fields
    init_form(params)

    @target = params["target"]
    unless valid_file_name?(@target)
      raise "invalid target file name."
    end
    
    yaml = @form.to_yaml

    target_file = get_target_file
    File.open(target_file, "w") do |io|
      io << yaml
    end
    
    publish(target_file)

    render :action => :index
  end
  
private  

  def publish(target)
    runner = SmallCage::Runner.new({:path => target })
    runner.update
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

  # XXX 同じファイル名が存在した場合の処理が未定。
  def new_target_file
    filename_template = Pathname.new(config["config_dir"]).join("filenames/" + config["file_out"] + ".rhtml")
    name = ERB.new(filename_template.read).result(binding)
    return config["source_dir"].join(name)
  end

  def get_target_file(only_exists = false)
    name = params["target"]
    return nil if name.nil?
    return nil unless valid_file_name?(name)
    result = config["source_dir"].join(name)
    if only_exists
      return nil unless result.file?
    end
    return result
  end
  
  def target_obj
    if @target_obj.nil?
      return nil if params["target"].nil?
      target_file = get_target_file
      return nil if target_file.nil?
      @target_obj = load_yaml_as_hash(target_file)
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
