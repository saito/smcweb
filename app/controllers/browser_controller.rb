class BrowserController < ApplicationController

  before_filter :read_site_config_filter
  attr_reader :config
  
  require 'pp'
  require 'pathname'

  def index
  end
  
  def tree
    @root = root
    @path = path
  end
  
  def tree_json
    @headers["content-type"] = "text/javascript+json; charset=utf-8"
    # @headers["content-type"] = "text/plain; charset=utf-8"
    @root = root
    @path = path
  end
  
  def view
    @root = root
    @path = path

    if @path.directory?
      render :action => :directory_index
    elsif @path.to_s =~ /\.smc$/
      @headers["content-type"] = "text/plain; charset=utf-8"
      render :text => File.new(@path).read
    else
      redirect_to "#{config['contents_root_uri']}/#{params['path']}"
    end
  end
  
  def form
    @root = root
    @path = path
    if @form.nil?
      @form = SimpleEditor.new
      @form.body = File.new(@path).read
      @form.path = params['path']
    end
  end
  
  def save
    @form = SimpleEditor.new(:form, params)
    @root = root
    @path = path(@form.path)
    
    open(@path, "w") do |io|
      io << @form.body
    end
    
    redirect_to :action => :view, :path => @form.path
  end
  

private

  def root
    return realpath(config["root"], Pathname.new("/"))  
  end

  def path(path = nil)
    path = params[:path] if path.nil?
  
    if path.is_a? Array
      path = path.join("/")
    else
      path = path.to_s
    end
    path = realpath(@root + path, @root)
    return path
  end

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
