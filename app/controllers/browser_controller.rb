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
      redirect_to "#{config['contents_root_uri']}/#{params['path']}"
    end
  end
  
  def menu
    @root = root
    @path = secure_path
    @item = current_item
  end
  
  def form
    @root = root
    @path = secure_path
    @item = current_item

    if @form.nil?
      @form = SimpleEditor.new
      @form.body = File.new(@path).read
      @form.file_name = @path.basename
    end
  end
  
  def save
    @form = SimpleEditor.new(params, :form)
    @root = root
    @path = secure_path
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

private

  def current_item
    realpath = @path
    path = Pathname.new(params["path"].to_s)
    uri = config['contents_root_uri'] + "/" + params["path"].to_s
    return DirectoryIndexItem.new(path, realpath, uri)
  end

  def directory_index
    @items = []

    Dir.new(@path).sort.each do |name|
      next if name =~ /^\./
    
      path = Pathname.new(params["path"].to_s) + name
      realpath = @path + name
      uri = config['contents_root_uri'] + "/" + path.to_s
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
