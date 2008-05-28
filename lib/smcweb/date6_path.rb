module Smcweb
  class Date6Path < DatePath
    def initialize(conf)
      super(conf, {"length" => 6})
    end
  end
end