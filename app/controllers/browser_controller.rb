class BrowserController < ApplicationController

  before_filter :read_site_config_filter
  attr_reader :config
  
  require 'pp'
  require 'pathname'
  require 'smallcage'


  def index
    @root = root
    @path = secure_path
  end
  
  def tree
    @root = root
    @path = secure_path
    if !@path.directory?
      @path = @path.parent
    end
  end
  
  def tree_json
    @headers["content-type"] = "text/javascript+json; charset=utf-8"
    @root = root
    @path = secure_path
  end
  
  def view
    @root = root
    @path = secure_path

    if @path.directory?
      directory_index
    elsif @path.to_s =~ /\.smc$/
      @headers["content-type"] = "text/plain; charset=utf-8"
      render :text => File.new(@path).read
    else
      sec = Time.now.tv_sec
      redirect_to "#{config['contents_root_uri'].to_s}/#{params['path'].to_s}?#{sec}"
    end
  end
  
  def menu
    @root = root
    @path = secure_path
    @item = current_item
    @prohibit_editing = prohibit_editing
  end
  
  def form
    @root = root
    @path = secure_path(@path, false)
    @item = current_item

    if @item.type == :smc && @path.exist?
      loader = SmallCage::Loader.new(@path)
      obj = loader.load(@path);
      editor = obj["dirs"].last["editor"]
      unless editor.nil?
        redirect_to :controller => "editor", :action => "index", :type => editor, :target => @path.basename
        return
      end
    end

    if @form.nil?
      @form = SimpleEditor.new
      @form.body = File.new(@path).read if @path.exist?
      @form.file_name = @path.basename
    end
  end
  
  def save
    @form = SimpleEditor.new(params, :form)
    @root = root
    @path = secure_path(@path, false)
    @item = current_item

    open(@path, "w") do |io|
      io << @form.body
    end
    
    if @item.type == :smc
      runner = SmallCage::Runner.new({:path => @path })
      runner.update
    end

    redirect_to :action => :view, :path => params[:path]
  end

  def upload
    @root = root
    @path = secure_path
    if @path.directory?
      upload_into_directory
    else
      upload_file
    end
    redirect_to :action => :main, :path => params[:path]
  end

  def upload_into_directory
    basename = params[:upload_file].original_filename
    
    file = @path + basename
    open(file, "wb") do |io|
      io << params[:upload_file].read
    end
  end
  private :upload_into_directory
  
  def upload_file
    open(@path, "wb") do |io|
      io << params[:upload_file].read
    end
  end
  private :upload_file
  
  def rename
    @form = SimpleEditor.new(params, :form)
    @root = root
    @path = secure_path
    raise "Error" unless @path.exist?
    
    new_name = @form.file_name.to_s.strip
    unless new_name.empty?
      new_path = @path.parent + new_name
      new_path = secure_path(new_path, false)
      File.rename(@path, new_path)
    end
    
    redirect_to :action => :main, :path => Pathname.new(params[:path]).parent + new_name
  end
  
  def delete
    @root = root
    @path = secure_path

    unless @path.file?    
      render :text => "error"
      return
    end
    
    File.unlink(@path)
#    Dir.new(@path.parent).sort.each do |name|
#      p name
#    end
    
    redirect_to :action => :main, :path => Pathname.new(params[:path]).parent
  end

  def publish
    @root = root
    @path = secure_path
    @item = current_item

    if @item.type == :smc || @item.type == :directory
      runner = SmallCage::Runner.new({:path => @path })
      runner.update
    else
      redirect_to :action => :main, :path => params[:path]
    end 

    if @item.type == :smc
      redirect_to :action => :main, :path => params[:path]
    else
      if (@path + "index.html").exist?
        redirect_to :action => :main, :path => (Pathname.new(params[:path].to_s) + "index.html").to_s
      else
        redirect_to :action => :main, :path => params[:path].to_s
      end
    end
  end

  def create_or_delete_directory
    @root = root
    @path = secure_path
    target = @path + params[:name]
    if params[:commit] == "Create new directory"
      if !params[:name].empty?
        target.mkdir
      end
    elsif params[:commit] == "Delete this directory"
      if target.exist? && target.children.length == 0
        target.rmdir
      end
      redirect_to :action => :main, :path => Pathname.new(params[:path]).parent.to_s
      return;
    end
    redirect_to :action => :main, :path => params[:path].to_s
  end
  
  def new
    @root = root
    path = secure_path + params[:name]
    redirect_to :action => :form, :path => path
  end

private

  def current_item
    realpath = @path
    path = Pathname.new(params["path"].to_s)
    uri = config['contents_root_uri'].to_s + "/" + params["path"].to_s
    return DirectoryIndexItem.new(path, realpath, uri)
  end

  def directory_index
    @items = []

    Dir.new(@path).sort.each do |name|
      next if name =~ /^\./
    
      path = Pathname.new(params["path"].to_s) + name
      realpath = @path + name
      uri = config['contents_root_uri'].to_s + "/" + path.to_s
      d = DirectoryIndexItem.new(path, realpath, uri)
      @items << d
    end
    
    order = {
      :directory => 0,
      :dirsmc => 1,
      :image => 2,
      :smc => 2,
      :file => 2
    }
    
    @items.sort! do |a,b|
      if order[a.type] == order[b.type]
        a.name <=> b.name
      else
        order[a.type] <=> order[b.type]
      end
    end
    
    render :action => :directory_index
  end

  def root
    return realpath(config["root"], Pathname.new("/"))
  end

  def secure_path(path = nil, must_exist = true)
    path = params[:path] if path.nil?
  
    if path.is_a? Array
      path = path.join("/")
    else
      path = path.to_s
    end
    path = realpath(@root + path, @root, must_exist)
    return path
  end

  # symlink?
  def realpath(path, parent, must_exist = true)
    path = Pathname.new(path)
    parent = parent.realpath.to_s
    
    if must_exist
      raise "path not found: #{path}" unless path.exist?
      path = path.realpath
    end

    unless path.to_s[0...parent.length] == parent
      raise "Illegal path: #{path.to_s}, #{parent}"
    end
    
    return path
  end

  # サイト設定ファイルのprohibit_editing_output_fileでtrueが指定されており、
  # 対応する.smcファイルが存在する場合にtrueを返す．
  def prohibit_editing
    if config["prohibit_editing_output_file"].nil? || !config["prohibit_editing_output_file"]
      return false;
    end
    return !@item.smc.nil?
  end


# XXX
  def test

puts "-" * 30  
  open("test.txt", "w") do |io|
    io << "test"
  end
  Dir.new(".").each do |f|
    puts "exists!" if f == "test.txt"
  end

  puts Pathname.new("test.txt").exist?
  puts File.delete("test.txt")
  puts Pathname.new("test.txt").exist?

  Dir.new(".").each do |f|
    puts "exists!" if f == "test.txt"
  end
render :text => "OK"  
  end
end
