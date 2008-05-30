module Smcweb
  class Increment4Path < IncrementPath
    def initialize(conf)
      super(conf, {"length" => 4})
    end
  end
end