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
    init_target(true)
    init_fields
    init_form_values

    @files = @path.list
    render_form
  end
  
  def init_target(create_new = false)
    path_args = params_to_path_args
    @target_file = @path.args_to_path(path_args.to_a)
    return if @target_file.nil? && ! create_new
    
    @target_file ||= @path.new_path
    init_target_original
  end
  private :init_target
  
  def init_target_original
    return unless @target_file.exist?
    @target_original = relpath(@target_file) 
  end
  private :init_target_original
  
  # create path args from parameters.
  # params["target"] / params["form"]["path_0"] 
  def params_to_path_args
    result = []
    
    if params["form"].nil?
      return target_to_path_args(params["target"])
    end

    params["form"].keys.sort.each do |k|
      result << params["form"][k] if k =~ /^path_\d+$/
    end
    return result
  end
  private :params_to_path_args

  def target_to_path_args(target)
    return nil if target.nil?
    return nil if target[0] == ?/
    target = config["root"] + target
    return @path.path_to_args(target)
  end
  private :target_to_path_args

  # create PathName from target string.
  # To validate target value, this method convert target to args, and create path from args.
  # target -> args -> path
  def target_to_path(target)
    args = target_to_path_args(target)
    return nil if args.nil?
    return @path.args_to_path(args)
  end
  private :target_to_path

  def save_or_delete
    if params[:submit] == "保存" # TODO 日本語
      save
    elsif params[:submit] == "削除"
      delete
    end
  end

  def overwrite_different_file?
    original = params[:target_original]
    current = relpath(@target_file).to_s
    
    # (新規 || リネーム) && ターゲットが存在 → 別のファイルを上書きしようとしている。
    return (original.nil? || original != current) && @target_file.exist?
  end
  private :overwrite_different_file?

  def save
    init_target
    if @target_file.nil?
      render :text => "ERROR: Illegal file name."
      return
    end
    
    if overwrite_different_file?
      render :text => "ERROR: try to overwrite different file."
      return
    end

    init_fields
    init_form_values(params)

    yaml = @form.to_yaml
    File.open(@target_file, "w") do |io|
      io << yaml
    end
    purge_old_file
    
    publish(@target_file)
    
    init_target_original

    @files = @path.list
    render_form
  end
  private :save

  # ファイル名が変更された場合、旧ファイルを削除
  def purge_old_file
    target_old = params[:target_original]
    if !target_old.nil? && target_old != relpath(@target_file).to_s
      file_old = target_to_path(target_old)
      exec_delete(file_old) unless file_old.nil?
    end
  end
  private :purge_old_file

  def delete
    init_target
    if ! @target_file.nil? && @target_file.file?
      exec_delete(@target_file)
      publish(nil)
    end
    redirect_to :action => "index"
  end
  private :delete
  
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
    File.delete(file) if file.exist?
    
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

  def get_target_files(only_exists = false)
    names = params[:targets]
    result = []
    names.each do |name|
      path = target_to_path(name)

      if path.exist? && ! path.file?
        raise "Target already exists, but not a file.: " + name
      elsif only_exists
        next unless path.file?
      end

      result << path
    end
    return result
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

  def render_form
    render :action => :index
  end
  private :render_form

end
