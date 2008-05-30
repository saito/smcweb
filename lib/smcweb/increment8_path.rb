module Smcweb
  class Increment8Path < IncrementPath
    def initialize(conf)
      super(conf, {"length" => 8})
    end
  end
end