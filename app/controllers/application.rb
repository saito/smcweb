# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :off
  
  def read_config_filter
    @config = read_env_config
    if @config.nil?
      render :text => "404 object not found.", :status => 404
      return false
    end
    return true
  end
  
  def relpath(path)
    return nil if path.nil?
    root = config["source_dir"].to_s
    unless path.to_s[0...root.length] == root
      return nil
    end
    return path.relative_path_from(config["source_dir"])
  end

private  

  def read_config(site, type)
    return nil unless site =~ /^[-\w]+$/
    return nil unless type =~ /^[-\w]+$/
    site_config_path = Pathname.new("#{RAILS_ROOT}/config/sites/#{site}_#{RAILS_ENV}.yml")
    return nil unless site_config_path.file?

    site_config = YAML.load(ERB.new(site_config_path.read).result(binding))
    
    type_dir = Pathname.new(site_config["config_dir"])
    root = search_document_root(type_dir)
    return nil if root.nil?

    type_config_path = type_dir.join("#{type}.yml")
    return nil unless type_config_path.file?
    
    type_config = YAML.load(ERB.new(type_config_path.read).result(binding))

    config = type_config.merge(site_config)

    return nil if config["path"].nil?
    return nil unless config["path"][0] == ?/

    config["root"] = root
    config["source_dir"] = root.join("." + config["path"])
    config["label"] = type.capitalize if config["label"].nil?
    config["file_in"] = Regexp.new(config["file_in"])
    
    return config
  end

  def search_document_root(path)
    30.times do
      if path.basename.to_s == "_smc" && path.directory?
        return path.parent.realpath
      end
      path = path.parent
    end
    
    return nil
  end

  def read_env_config()
    site = params[:site].to_s
    type = params[:type].to_s
    return read_config(site, type)
  end
  
end
