module Smcweb
  class Date10Path < DatePath
    def initialize(conf)
      super(conf, {"length" => 10})
    end
  end
end