module Smcweb
  class BasePath
  
    # parse path like /news/{date14}_en.html.smc
    # 
    # return {
    #   :root => "/news",
    #   :type => "date14"
    #   :prefix => "",
    #   :suffix => "_en.html.smc"
    # }
    def parse_string_path_config(str)
      result = {}
      unless str =~ /\{([-\w]+?)\}/
        throw Exception.new("Illegal string path config:" + str)
      end
      result["type"] = $1

      prematch = $`
      postmatch = $'

      # suffix can't include "/"
      throw Exception.new("Illegal string path config:" + str) if postmatch.include?("/")
      result["suffix"] = postmatch
      
      prematch =~ %r{(.*)/([^/]*)}
      
      if $1.to_s.empty? 
        result["root"] = "/"
      else
        result["root"] = $1
      end
      result["prefix"] = $2
      
      return result
    end
  end
end