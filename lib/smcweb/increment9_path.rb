module Smcweb
  class Increment9Path < IncrementPath
    def initialize(conf)
      super(conf, {"length" => 9})
    end
  end
end