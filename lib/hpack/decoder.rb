module Hpack
  class Decoder
    class DecodingError < StandardError; end
    class ZeroIndexedFieldIndex < DecodingError; end

    attr_reader :lookup_table

    def initialize lookup_table_size: LookupTable::SETTINGS_HEADER_TABLE_SIZE
      @lookup_table = LookupTable.new max_size: lookup_table_size
    end

    def decode input
      headers = []

      read_fields_from input do |field|
        if block_given?
          yield field.header, field.value, field
        end

        headers << [field.header, field.value, field]
      end

      headers
    end

    private

    def read_fields_from input
      while not input.eof?
        header_byte = input.readbyte
        input.ungetbyte header_byte

        if header_byte & 0b1000_0000 == 0b1000_0000
          # Indexed Header Field Representation
          index = read_integer_with_prefix length: 7, input: input

          if index == 0
            raise ZeroIndexedFieldIndex
          end

          header = @lookup_table[index].name
          value = @lookup_table[index].value

          yield Field.new header, value

        elsif header_byte & 0b1100_0000 == 0b0100_0000
          # Literal Header Field with Incremental Indexing

          header, value = read_literal_field 6, input
          @lookup_table << LookupTable::Entry.new(header, value)
          yield Field.new header, value

        elsif header_byte & 0b1111_0000 == 0b0000_0000
          # Literal Header Field without Indexing

          header, value = read_literal_field 4, input
          yield Field.new header, value

        elsif header_byte & 0b1111_0000 == 0b0001_0000
          # Literal Header Field never Indexed

          header, value = read_literal_field 4, input
          yield Field.new header, value

        elsif header_byte & 0b1110_0000 == 0b0010_0000
          # Dynamic Table Size Update

          new_size = read_integer_with_prefix length: 5, input: input

          @lookup_table.max_size = new_size
        end
      end
    end

    def read_integer_with_prefix *options
      integer_reader.read(*options)
    end

    def read_string input
      header_byte = input.readbyte
      input.ungetbyte header_byte
      huffman = (header_byte & 0b1000_0000 != 0)
      length = read_integer_with_prefix length: 7, input: input

      if huffman
        huffman_decoder.decode input: input, length: length
      else
        input.read length
      end
    end

    def read_literal_field prefix_length, input
      name_index = read_integer_with_prefix length: prefix_length, input: input
      if name_index == 0
        header = read_string input
      else
        header = @lookup_table[name_index].name
      end

      value = read_string input

      [header, value]
    end

    def huffman_decoder
      @huffman_decode ||= Hpack::Huffman.new
    end

    def integer_reader
      @integer_reader ||= Hpack::IntegerReader.new
    end
  end
end
