module Smcweb
  class Increment6Path < IncrementPath
    def initialize(conf)
      super(conf, {"length" => 6})
    end
  end
end