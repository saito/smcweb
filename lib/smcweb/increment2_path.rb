module Smcweb
  class Increment2Path < IncrementPath
    def initialize(conf)
      super(conf, {"length" => 2})
    end
  end
end