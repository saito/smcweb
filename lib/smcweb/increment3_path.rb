module Smcweb
  class Increment3Path < IncrementPath
    def initialize(conf)
      super(conf, {"length" => 3})
    end
  end
end