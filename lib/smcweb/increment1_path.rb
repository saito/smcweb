module Smcweb
  class Increment1Path < IncrementPath
    def initialize(conf)
      super(conf, {"length" => 1})
    end
  end
end