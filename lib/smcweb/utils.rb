module Smcweb
  class Utils
  
    # emulate smc loading.
    def self.loadsmc(file)
      docs = YAML.load_stream(File.read(file)).documents

      result = {}
      string_count = 0
      arrays_count = 0
      docs.each do |doc|
        if doc.is_a? String
          if string_count == 0
            result["strings_0"] = doc
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

  end
end