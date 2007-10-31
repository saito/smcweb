# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :off
  
  MAX_ROOT_SEARCH = 30
  
private  

  def read_config_filter
    site = params[:site].to_s
    type = params[:type].to_s
    @config = read_config(site, type)

    if @config.nil?
      render :text => "404 object not found.", :status => 404
      return false
    end
    return true
  end

  def read_site_config_filter
    site = params[:site].to_s
    @config = read_site_config(site)

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

  def load_yaml_as_hash(file)
    docs = YAML.load_stream(File.read(file)).documents

    result = {}
    string_count = 0
    arrays_count = 0
    docs.each do |doc|
      if doc.is_a? String
        if string_count == 0
          result["body"] = doc
        else
          result["strings_#{string_count}"] = doc
        end
        string_count += 1
      elsif doc.is_a? Array
        result["arrays_#{arrays_count}"] = doc
        arrays_count += 1
      elsif doc.is_a? Hash
        doc.keys.each do |k|
          next if k == "strings" || k == "arrays"
          result[k] = doc[k]
        end
      end
    end
    
    return result    
  end

  def read_site_config(site)
    return nil unless site =~ /^[-\w]+$/
    site_config_path = Pathname.new("#{RAILS_ROOT}/config/sites/#{site}_#{RAILS_ENV}.yml")
    return nil unless site_config_path.file?

    site_config = YAML.load(ERB.new(site_config_path.read).result(binding))
    
    config_dir = Pathname.new(site_config["config_dir"])
    root = search_document_root(config_dir)
    return nil if root.nil?
    
    pp root
    site_config["root"] = root
    
    return site_config
  end

  def read_config(site, type)
    read_site_config(site)
    
    return nil unless type =~ /^[-\w]+$/

    type_config_path = type_dir.join("#{type}.yml")
    return nil unless type_config_path.file?
    
    docs = YAML.load_stream(ERB.new(type_config_path.read).result(binding)).documents
    type_config = docs[0]
    description = docs[1]

    config = type_config.merge(site_config)

    return nil if config["path"].nil?
    return nil unless config["path"][0] == ?/

    config["source_dir"] = root.join("." + config["path"])
    config["label"] = type.capitalize if config["label"].nil?
    config["filename_in"] = Regexp.new(config["filename_in"])
    config["description"] = description
    
    return config
  end

  def search_document_root(path)
    MAX_ROOT_SEARCH.times do
      if path.basename.to_s == "_smc" && path.directory?
        return path.parent.realpath
      end
      path = path.parent
    end
    
    return nil
  end

end
