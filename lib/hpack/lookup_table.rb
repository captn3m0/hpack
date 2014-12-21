module Hpack
  class LookupTable
    class IndexOutOfBounds < StandardError; end

    class Entry
      attr_accessor :name
      attr_accessor :value

      def initialize name, value = ""
        @name = name
        @value = value
      end

      def size
        32 + name.length + value.length
      end

      def to_a
        [name, value]
      end

      def to_s
        "(s = %4d) %s: %s" % [size, name, value]
      end
    end

    SETTINGS_HEADER_TABLE_SIZE = 4096
    STATIC_TABLE_SIZE = 61
    STATIC_ENTRIES = [
      [":authority"],
      [":method", "GET"],
      [":method", "POST"],
      [":path", "/"],
      [":path", "/index.html"],
      [":scheme", "http"],
      [":scheme", "https"],
      [":status", "200"],
      [":status", "204"],
      [":status", "206"],
      [":status", "304"],
      [":status", "400"],
      [":status", "404"],
      [":status", "500"],
      ["accept-charset"],
      ["accept-encoding", "gzip, deflate"],
      ["accept-language"],
      ["accept-ranges"],
      ["accept"],
      ["access-control-allow-origin"],
      ["age"],
      ["allow"],
      ["authorization"],
      ["cache-control"],
      ["content-disposition"],
      ["content-encoding"],
      ["content-language"],
      ["content-length"],
      ["content-location"],
      ["content-range"],
      ["content-type"],
      ["cookie"],
      ["date"],
      ["etag"],
      ["expect"],
      ["expires"],
      ["from"],
      ["host"],
      ["if-match"],
      ["if-modified-since"],
      ["if-none-match"],
      ["if-range"],
      ["if-unmodified-since"],
      ["last-modified"],
      ["link"],
      ["location"],
      ["max-forwards"],
      ["proxy-authenticate"],
      ["proxy-authorization"],
      ["range"],
      ["referer"],
      ["refresh"],
      ["retry-after"],
      ["server"],
      ["set-cookie"],
      ["strict-transport-security"],
      ["transfer-encoding"],
      ["user-agent"],
      ["vary"],
      ["via"],
      ["www-authenticate"],
    ]

    def initialize max_size: SETTINGS_HEADER_TABLE_SIZE
      @max_size = max_size
      @dynamic_entries = []
    end

    def [] index
      if index <= STATIC_TABLE_SIZE
        Entry.new(*STATIC_ENTRIES[index - 1])
      else
        dynamic_index = index - STATIC_TABLE_SIZE - 1
        size = @dynamic_entries.length

        if dynamic_index >= size
          raise IndexOutOfBounds, "#{dynamic_index} is greater than dynamic table size #{size}"
        end

        @dynamic_entries[dynamic_index]
      end
    end

    # 4.1 Calculating Table Size
    #
    # The size of the dynamic table is the sum of the size of its entries.
    #
    # The size of an  entry is the sum of its  name's length in octets
    # (as defined in  Section 5.2), its value's length  in octets (see
    # Section 5.2), plus 32.
    #
    # The size of an entry is  calculated using the length of the name
    # and value without any Huffman encoding applied.
    #
    # NOTE:  The  additional  32   octets  account  for  the  overhead
    # associated with an entry. For  example, an entry structure using
    # two 64-bit pointers  to reference the name and the  value of the
    # entry,  and  two 64-bit  integers  for  counting the  number  of
    # references  to  the name  and  value  would  have 32  octets  of
    # overhead.
    #
    def size
      @dynamic_entries
        .map(&:size)
        .reduce(0, :+)
    end

    def max_size
      @max_size
    end

    def max_size= value
      @max_size = value
      evict
    end

    def << entry
      @dynamic_entries.unshift entry
      evict
    end

    def to_s
      table = @dynamic_entries
        .each_with_index
        .map { |e, i| "[%4s] %s" % [i + 1, e.to_s] }
        .join "\n"

      summary = "       Table size: #{size}"

      table + "\n" + summary
    end

    private

    def evict
      overflow = size - max_size
      while overflow > 0
        evicted_entry = @dynamic_entries.pop
        overflow -= evicted_entry.size
      end
    end
  end
end
