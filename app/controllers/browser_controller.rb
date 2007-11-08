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

private

  def root
    return realpath(config["root"], Pathname.new("/"))  
  end

  def path
    if params[:path].is_a? Array
      path = params[:path].join("/")
    else
      path = params[:path].to_s
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
