module Smcweb
  class Increment7Path < IncrementPath
    def initialize(conf)
      super(conf, {"length" => 7})
    end
  end
end