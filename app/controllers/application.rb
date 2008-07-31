# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :off
  
  MAX_ROOT_SEARCH = 30
  
  def relpath(path)
    return nil if path.nil?
    root = config["root"].to_s
    unless path.to_s[0...root.length] == root
      return nil
    end
    return path.relative_path_from(config["root"])
  end

  def read_config_filter
    site = params[:site].to_s
    type = params[:type].to_s
    @config = read_config(site, type)

    if @config.nil?
      render :text => "404 object not found.", :status => 404
      return false
    end

    @path = create_path_config(config)
    return true
  end
  private :read_config_filter

  def read_site_config_filter
    site = params[:site].to_s
    @config = read_site_config(site)

    if @config.nil? 
      render :text => "404 object not found.", :status => 404
      return false
    end
    return true
  end
  private :read_site_config_filter
  
  def load_yaml_as_hash(file)
    return Smcweb::Utils.loadsmc(file)
  end
  private :load_yaml_as_hash

  def read_site_config(site)
    return nil unless site =~ /^[-\w]+$/ 
    site_config_path = Pathname.new("#{RAILS_ROOT}/config/sites/#{site}_#{RAILS_ENV}.yml")

    return nil unless site_config_path.file? # 404 not found

    site_config = YAML.load(ERB.new(site_config_path.read).result(binding))
    
    config_dir = Pathname.new(site_config["config_dir"])
    root = search_document_root(config_dir)
    throw Exception.new("smc root directory not found.") if root.nil?
    
    site_config["root"] = root
    site_config["site_config_dir"] = config_dir
    
    return site_config
  end
  private :read_site_config

  def read_config(site, type)
    site_config = read_site_config(site)

    return nil if site_config.nil?
    return nil unless type =~ /^[-\w]+$/

    type_config_path = site_config["site_config_dir"] + "#{type}.yml"
    return nil unless type_config_path.file?
    
    docs = YAML.load_stream(type_config_path.read).documents
    type_config = docs[0]
    description = docs[1]
    config = type_config.merge(site_config)
    config["description"] = description
    
    return config
  end
  private :read_config

  def create_path_config(config)
    path_class = nil
    if config["path"].is_a? String
      type = config["path"].match(/\{([-\w]+?)\}/).to_a[1]
      
      if type.nil?
        path_class = Smcweb::FixPath
      else
        path_class = get_path_config_class(type)
      end
    else
      type = config["path"]["type"]
      path_class = get_path_config_class(type)
    end
    throw Exception.new("Can't create path config: " + type) if path_class.nil?
    return path_class.new(config)
  end
  private :create_path_config
  
  def get_path_config_class(type)
    # TODO at first search from project directory

    cname = type.camelize + "Path"
    return Smcweb.const_get(cname)
  end
  private :get_path_config_class

  def search_document_root(path)
    MAX_ROOT_SEARCH.times do
      if path.basename.to_s == "_smc" && path.directory?
        return path.parent.realpath
      end
      path = path.parent
    end
    
    return nil
  end
  private :search_document_root

end
