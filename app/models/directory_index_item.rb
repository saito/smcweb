class DirectoryIndexItem
  attr_accessor :name, :path, :realpath, :uri, :type, :text_editable
    
  def initialize(path, realpath, uri)
    @path = path
    @uri = uri
    @name = path.basename.to_s
    @realpath = realpath
    @text_editable = false

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
  end
end