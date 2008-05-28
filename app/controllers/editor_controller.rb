class EditorController < ApplicationController
  require 'smallcage'

  before_filter :read_config_filter
  attr_reader :config
  layout "default"
  
  def test
    p @path.new_path
    render :text => "OK"
  end

  def index
    @files = @path.list
    @target_file = @path.args_to_path(params_to_path_args)
    @target_file ||= @path.new_path
    
    init_fields
    init_form_values
    render_form
  end
  
  def params_to_path_args
    result = []
    return result if params["form"].nil?

    params["form"].keys.sort.each do |k|
      result << params["form"][k] if k =~ /^path_\d+$/
    end
    return result
  end
  private :params_to_path_args

  def save_or_delete
    if params[:submit] == "保存" # TODO 日本語
      save
    elsif params[:submit] == "削除"
      delete
    end
  end

  def save
    @target_file = @path.args_to_path(params_to_path_args)
    if @target_file.nil?
      render :text => "ERROR: Illegal file name."
      return
    end

    # (新規 || リネーム) && 重複 -> ファイル名再発番
    # if ((params[:target_original].nil? || params[:target] != params[:target_original]) && @target_file.file?)
    #   file_name = resolve_file_name(@target_file.basename.to_s)
    #   @target_file = @target_file.parent.join(file_name)
    # end
    # @target = relpath(@target_file)
    
    init_fields
    init_form_values(params)

    yaml = @form.to_yaml
    File.open(@target_file, "w") do |io|
      io << yaml
    end
    # purge_old_file
    
    publish(@target_file)

    @files = @path.list
    render_form
  end

  def purge_old_file
    # ファイル名が変更された場合、旧ファイルを削除
    target_old = params[:target_original]
    if !target_old.nil? && target_old != params[:target]
      file_old = get_target_file(true, target_old) # XXX
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

  def publish(target_file)
    path = @config["publish"]
    if path.nil?
      exec_publish(target_file)
    else
      publish_config_path(path, target_file)
    end
  end
  private :publish
  
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
  private :publish_config_path
  
  def exec_publish(target_file)
    return if target_file.nil?
    runner = SmallCage::Runner.new({:path => target_file })
    runner.update
  end
  private :exec_publish

  def exec_delete(file)
    File.delete(file)
    
    if file.to_s =~ /\.smc$/
      out_file = file.to_s[0...-4]
      if Pathname.new(out_file).file?
        File.delete(out_file)
      end
    end
  end
  private :exec_delete

  def init_fields
    if ! form_config.nil?
      @fields = SmcField.create_from_config(form_config)
    elsif ! target_obj.nil?
      @fields = SmcField.create_from_sample(target_obj)
    elsif ! sample_obj.nil?
      @fields = SmcField.create_from_sample(sample_obj)
    end
  end
  private :init_fields
  
  def init_form_values(params = nil)
    @form = SmcForm.new(@fields)
    
    # values came from outside
    if ! params.nil?
      @form.params = params["form"]
      return
    end

    # values came from inside
    values = {}
    if ! target_obj.nil? # YAML
      values = target_obj
    elsif ! form_config.nil? # default
      form_config.each do |c|
        values[c["name"]] = c["value"]
      end
    elsif ! sample_obj.nil? # auto
      values = { "template" => sample_obj["template"] }
    end
    
    @form.values = values
    @form.path_args = target_file_path_args
  end
  private :init_form_values
  
  def target_file_path_args
    return @path.path_to_args(@target_file)
  end
  private :target_file_path_args

  def new_target_file
    filename_template = Pathname.new(config["config_dir"]).join("filenames/" + config["filename_out"] + ".rhtml")
    erb = ERB.new(filename_template.read)
    return format_new_target_file(erb)
  end
  private :new_target_file

  def format_new_target_file(erb)
    name = erb.result(binding)
    name = resolve_file_name(name)
    return get_source_file_path(name)
  end
  private :format_new_target_file

  def resolve_file_name(name)
    @filename_retry = 0
    target = get_source_file_path(name)
    return name if !target.exist?
    if config["filename_retry"].to_s.empty? || config["filename_retry"].to_i < @filename_retry
      return target
    end
    @filename_retry += 1

    # XXX
    # if name =~ /-\d+\./
    #   result = increment_branch_number(name)
    # else
    #   result = add_number_before_period(name)
    # end

    return resolve_file_name(result)
  end
  private :resolve_file_name

  def get_source_file_path(name)
    target = Pathname.new(config["source_dir"]).join(name)    
  end
  private :get_source_file_path


  def get_target_file(only_exists = false)
  
  end
  private :get_target_file

  def get_target_file_OLD(only_exists = false, name = nil)
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
  private :get_target_file_OLD

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
  private :get_target_files

  def target_obj
    if @target_obj.nil?
      return nil unless @target_file.exist?
      @target_obj = load_yaml_as_hash(@target_file)
    end
    return @target_obj
  end
  private :target_obj

  def sample_obj
    if @sample_obj.nil?
      return nil if @files.size <= 0
      sample_file = @files[0]
      @sample_obj = load_yaml_as_hash(sample_file)
    end
    return @sample_obj
  end
  private :sample_obj

  def form_config
    if @form_config.nil?
      @form_config = load_form_config
    end
    return @form_config
  end
  private :form_config

  def load_form_config
    name = config["form"]
    return nil if name.nil?
    file = Pathname.new(config["config_dir"]).join("forms/" + name + ".yml")
    raise "form config file not exists: " + file.to_s unless file.file?
    
    config = YAML.load(File.read(file))
    raise "form config must be array: " + file.to_s unless config.is_a?(Array)

    return config
  end
  private :load_form_config

  def valid_file_name?(name)
    return name =~ config["filename_in"]
  end
  private :valid_file_name?

  def render_form
    render :action => :index
  end
  private :render_form

end
