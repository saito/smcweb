module Smcweb
  class Increment5Path < IncrementPath
    def initialize(conf)
      super(conf, {"length" => 5})
    end
  end
end