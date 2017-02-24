module Hpack
  class Encoder
    class EncodingError < StandardError; end

    attr_reader :lookup_table

    def initialize lookup_table_size: LookupTable::SETTINGS_HEADER_TABLE_SIZE
      @lookup_table = LookupTable.new max_size: lookup_table_size
    end

    def encode headers
      headers.each_index do |key, value|
        @lookup_table[key]
      end
    end
  end
end
