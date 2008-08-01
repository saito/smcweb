class CommandController < ApplicationController
  before_filter :read_config_filter
  attr_reader :config

  layout "default"
  require "pp"

  def exec
    cdata = get_command(params["id"])
    if cdata.nil?
      render :text => "ERROR: No such command."
      return
    end

    @result = ""
    
    if cdata["command"][0] == ?/
      command = cdata["command"]
    else
      command = config["config_dir"] + "/" + cdata["command"]
    end
    
    begin    
      open("| #{command}") do |io|
        @result += io.read
      end
    rescue => ex
      logger.error(ex)
      @result = ex.to_s
    end
    
    @command = command
    @command_data = cdata
  end
  
  private
  
  def get_command(name)
    return nil if config["commands"].nil?

    config["commands"].each do |c|
      if c["name"] == name
        return c
      end
    end
    return nil
  end

end
