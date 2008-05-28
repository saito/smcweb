module Smcweb
  class Date14Path < DatePath
    def initialize(conf)
      super(conf, {"length" => 14})
    end
  end
end