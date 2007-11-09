class BrowserController < ApplicationController

  before_filter :read_site_config_filter
  attr_reader :config
  
  require 'pp'
  require 'pathname'

  def index
  end
  
  def tree
    @root = root
    @path = secure_path
  end
  
  def tree_json
    @headers["content-type"] = "text/javascript+json; charset=utf-8"
    # @headers["content-type"] = "text/plain; charset=utf-8"
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
  
  def form
    @root = root
    @path = secure_path
    if @form.nil?
      @form = SimpleEditor.new
      @form.body = File.new(@path).read
      @form.path = params['path']
    end
  end
  
  def menu
    @root = root
    @path = secure_path

    path = Pathname.new(params["path"].to_s)
    realpath = @path
    uri = config['contents_root_uri'] + "/" + params["path"].to_s
    @item = DirectoryIndexItem.new(path, realpath, uri)
  end
  
  def save
    @form = SimpleEditor.new(:form, params)
    @root = root
    @path = secure_path(@form.path)
    
    open(@path, "w") do |io|
      io << @form.body
    end
    
    redirect_to :action => :view, :path => @form.path
  end

  class DirectoryIndexItem
    attr_accessor :name, :path, :realpath, :uri, :type
    
    def initialize(path, realpath, uri)
      @path = path
      @uri = uri
      @name = path.basename.to_s
      @realpath = realpath

      if realpath.directory?
        @type = :directory
      elsif @name == "_dir.smc"
        @type = :dirsmc
      elsif @name =~ /\.(?:jpe?g|gif|png)$/
        @type = :image
      else
        @type = :file
      end
    end
  end

private

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
      :file => 3
    }
    
    @items.sort! do |a,b|
      if a.type == b.type
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

  def secure_path(path = nil)
    path = params[:path] if path.nil?
  
    if path.is_a? Array
      path = path.join("/")
    else
      path = path.to_s
    end
    path = realpath(@root + path, @root)
    return path
  end

  # symlink?
  def realpath(path, parent)
    path = Pathname.new(path)
    raise "path not found: #{path}" unless path.exist?
    path = path.realpath
    
    parent = parent.realpath.to_s

    unless path.to_s[0...parent.length] == parent
      raise "Illegal path: #{path.to_s}, #{parent}"
    end
    
    return path
  end

end
