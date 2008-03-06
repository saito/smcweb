class EditorController < ApplicationController

  before_filter :read_config_filter
  attr_reader :config
  layout "default"
  
#  require 'pp'
  require 'smallcage'

  def index
    @files = get_files
    @target_file = get_target_file(true)
    @target_file ||= new_target_file
    @target = relpath(@target_file)
    @is_new = params[:target].nil?

    init_fields
    init_form
    render_form
  end
  
  def save_or_delete
    if params[:submit] == "保存"
      save
    elsif params[:submit] == "削除"
      delete
    end
  end

  def save
    @files = get_files
    @target_file = get_target_file(false)
    if @target_file.nil?
      render :text => "ERROR: Illegal file name."
      return;
    end

    # (新規 || リネーム) && 重複 -> ファイル名再発番
    if ((params[:target_original].nil? || params[:target] != params[:target_original]) && @target_file.file?)
      file_name = resolve_file_name(@target_file.basename.to_s)
      @target_file = @target_file.parent.join(file_name)
    end

    @target = relpath(@target_file)
    
    init_fields
    init_form(params)

    yaml = @form.to_yaml
    File.open(@target_file, "w") do |io|
      io << yaml
    end
    purge_old_file
    
    publish(@target_file)

    @files = get_files
    render_form
  end

  def purge_old_file
    # ファイル名が変更された場合、旧ファイルを削除
    target_old = params[:target_original]
    if !target_old.nil? && target_old != params[:target]
      file_old = get_target_file(true, target_old)
      exec_delete(file_old) unless file_old.nil?
    end
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
  
  def delete_multiple
    targets = get_target_files(true)
    if !targets.nil?
      targets.each do |t|
        exec_delete(t)
      end
      publish(nil)
    end
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
      if Pathname.new(out_file).file?
        File.delete(out_file)
      end
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
    filename_template = Pathname.new(config["config_dir"]).join("filenames/" + config["filename_out"] + ".rhtml")
    erb = ERB.new(filename_template.read)
    return format_new_target_file(erb)
  end  

  def format_new_target_file(erb)
    name = erb.result(binding)
    name = resolve_file_name(name)
    return get_source_file_path(name)
  end

  def resolve_file_name(name)
    @filename_retry = 0
    # 同名ファイルが存在する場合"-n"を添付、"-n"が存在する場合は加算
    target = get_source_file_path(name)
    return name if !target.exist?
    if config["filename_retry"].to_s.empty? || config["filename_retry"].to_i < @filename_retry
      return target
    end
    @filename_retry += 1
    
    if name =~ /-\d+\./
      result = increment_branch_number(name)
    else
      result = add_number_before_period(name)
    end

    return resolve_file_name(result)
  end

  def increment_branch_number(name)
    result = ""
    /(.+)-(\d+)\.(.+)/ =~ name
    num = $2.to_i + 1
    return $1 + "-" + num.to_s + "." + $3
  end

  def add_number_before_period(name)
    result = ""
    tokens = name.split(".")
    return name if tokens.size <= 1
    tokens.each do |token|
      if result.empty?
        result += token + "-" + @filename_retry.to_s
      else
        result += "." + token
      end
    end
    return result;
  end

  def get_source_file_path(name)
    target = Pathname.new(config["source_dir"]).join(name)    
  end

  def get_target_file(only_exists = false, name = nil)
    name = params["target"] if name.nil?
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

  def get_target_files(only_exists = false)
    names = params[:targets]
    return nil if names.nil?
    files = []
    names.each do |n|
      result = config["source_dir"].join(n)
      if result.exist? && ! result.file?
        raise "Target already exists, but not a file.: " + name
      elsif only_exists
        next unless result.file?
      end
      files.push(result)
    end
    return files
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
    return name =~ config["filename_in"]
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

  def render_form
    layout = find_layout
    if layout.nil?
      render :action => :index
    else
      render(:file => layout, :use_full_path => false)
    end
  end

  def find_layout
    dir = config["site_config_dir"] + "forms"
    return nil if (dir.nil?)

    file_name = params[:type] + ".rhtml"
    file_name = params[:type] + ".html.erb" unless (dir + file_name).file?

    if (dir + file_name).file?
      return (dir + file_name).to_s
    end
    return nil
  end

end
