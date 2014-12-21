module Hpack
  class Field
    attr_reader :header
    attr_reader :value

    def initialize header, value
      @header = header
      @value = value
    end
  end
end
