class EditorController < ApplicationController

  before_filter :read_config_filter
  attr_reader :config
  layout "default"
  
  require 'pp'
  require 'smallcage'
  

  def index
    @files = get_files
    @fields = get_fields
    @form = SmcForm.new(@fields)
    
    target = relpath(get_target_file)
    if target.nil?
      target = relpath(new_target_file)
    end
    @target = target
  end
  
  def save
    @files = get_files
    @fields = get_fields
    @form = SmcForm.new(@fields, params["form"])
    @target = params["target"]

    unless valid_file_name?(@target)
      raise "invalid target file name."
    end
    
    yaml = @form.to_yaml

    target = get_target_file
    File.open(target, "w") do |io|
      io << yaml
    end
    
    runner = SmallCage::Runner.new({:path => target })
    runner.update
    
    render :action => :index
  end

private  

  def new_target_file
    filename_template = Pathname.new(config["config_dir"]).join("filenames/" + config["file_out"] + ".rhtml")
    name = ERB.new(filename_template.read).result(binding)
    return config["source_dir"].join(name)
  end

  def get_target_file
    name = params["target"]
    return nil if name.nil?
    return nil unless valid_file_name?(name)
    return config["source_dir"].join(name)
  end
  
  def get_fields
    target_file = get_target_file
    if target_file.nil? || ! target_file.file?
      target_file = @files[0]
      new_file = true
    else
      new_file = false
    end
    
    loader = SmallCage::Loader.new(config["root"])
    target = loader.load(target_file)
    
    exclude = %w{uri dirs strings arrays path}
    
    result = {}
    order = []
    target.keys.each do |k|
      next if exclude.include? k
    
      f = SmcField.new()
      f.name = k
      f.typ = "text"
      f.label = f.name.capitalize
      
      if ! new_file || k == "template"
        f.value = target[k]
      end
      
      result[k] = f
      order << k
    end
    
    f = SmcField.new()
    k = "body"
    f.name = k
    f.typ = "textarea"
    f.label = f.name.capitalize
    unless new_file
      f.value = target["strings"][0]
    end
    result[k] = f
    order << k
    
    def result.ordered_keys
      return @order
    end
    def result.ordered_keys=(order)
      @order = order
    end
    
    result.ordered_keys = order

    return result
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
