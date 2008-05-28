module Smcweb
  class Date12Path < DatePath
    def initialize(conf)
      super(conf, {"length" => 12})
    end
  end
end