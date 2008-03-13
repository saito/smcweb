class DirectoryIndexItem
  attr_accessor :name, :path, :realpath, :uri, :type, :text_editable, :smc, :output
    
  def initialize(path, realpath, uri)
    @path = path
    @uri = uri
    @name = path.basename.to_s
    @realpath = realpath
    @text_editable = false
    @smc = nil
    @output = nil

    if realpath.directory?
      @type = :directory
    elsif @name == "_dir.smc"
      @type = :dirsmc
      @text_editable = true
    elsif @name =~ /\.(?:jpe?g|gif|png)$/
      @type = :image
    elsif @name =~ /\.smc$/
      @type = :smc
      @text_editable = true
    else
      @type = :file
      @text_editable = true
    end
    
    if @realpath.file?
      source = @realpath.parent + (@realpath.basename.to_s + ".smc")
      if source.file?
        @smc = @path.to_s + ".smc"
      end
      if @type == :smc
        subname = @name.sub(/\.smc$/, "")
        output = @realpath.parent + subname
        if output.file?
          @output = (@path.parent + subname).to_s
        end
      end
    end
  end
end
