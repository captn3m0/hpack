module Hpack
  class IntegerReader
    def read length: 7, input: nil, start_with: 0
      prefix_mask = 0xFF >> (8 - length)
      result = start_with & prefix_mask

      return result if result != prefix_mask

      index = 0
      begin
        next_byte = input.readbyte
        result += (next_byte & 0b0111_1111) << (7 * index)
        index += 1
      end until next_byte & 0b1000_0000 == 0

      result
    end
  end
end
