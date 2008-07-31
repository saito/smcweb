module EditorHelper

  def contains_type(type)
    @fields.each do |f|
      if f.field_type == type
        return true
      end
    end
    return false
  end

  def filename_override?
    override = @config["filename_override"]
    return (!override.nil? && !override["type"].nil?)
  end

  def render_part(name)
    return render(:partial => name)
  end

end
