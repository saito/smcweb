module BrowserHelper

  def each_files(root, path)
    pwd = root + path
    dir = Dir.new(pwd)

    files = []
    
    dir.each do |name|
      path = pwd + name
      if path.directory?
        yield(name, path, relpath(root, path))
      else
        files << [name, path, relpath(root, path)]
      end
    end
    
    files.each do |f|
      yield(*f)
    end
  end

  def relpath(root, path)
    root = root.to_s
    path = path.to_s
    return path[(root.length + 1) .. -1]
  end

end
