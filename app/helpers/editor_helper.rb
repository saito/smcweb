module EditorHelper

  def render_part(name)
    dir = @config["site_config_dir"]
    if (dir.nil?)
      return render(:partial => name)
    end

    form_name = "forms/_" + name + ".rhtml"
    form_name = "forms/" + name + ".rhtml" unless (dir + form_name).file?
    form_name = "forms/_" + name + ".html.erb" unless (dir + form_name).file?
    form_name = "forms/" + name + ".html.erb" unless (dir + form_name).file?

    if (dir + form_name).file?
      file = dir + form_name
      return render(:file => file.to_s, :use_full_path => false)
    else
      return render(:partial => name)
    end
  end

end
