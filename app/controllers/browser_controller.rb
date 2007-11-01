class BrowserController < ApplicationController

  before_filter :read_site_config_filter
  attr_reader :config

  require 'pp'

private

  def index
  end
  
  def tree
    @root = config["root"]
    @path = ""
  end
  
  def tree_json
    @root = config["root"]
    if params[:path].is_a? Array
      @path = params[:path].join("/")
    else
      @path = params[:path].to_s
    end
  end

private

end


  
