module Smcweb
  class Date8Path < DatePath
    def initialize(conf)
      super(conf, {"length" => 8})
    end
  end
end