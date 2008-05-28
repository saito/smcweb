module Smcweb
  class Date4Path < DatePath
    def initialize(conf)
      super(conf, {"length" => 4})
    end
  end
end