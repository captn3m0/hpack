require 'json'
require 'pp'

RSpec.describe Hpack::Decoder do
  RSpec::Matchers.define :have_dynamic_entry_at_position do |position, header, value|
    match do |actual|
      entry = actual[Hpack::LookupTable::STATIC_TABLE_SIZE + position]
      expect(entry.name).to eq header
      expect(entry.value).to eq value
    end

    failure_message do |actual|
      """Expected that
#{actual}
would include '#{header}: #{value}' at position #{position}"
    end
  end

  def input_fixture data
    io = StringIO.new
    io.write [data.gsub(/\s/, "")].pack "H*"
    io.rewind
    io
  end

  def convert_headers_to_testcase(headers)
    headers.map {|h| {h[0] => h[1]}}
  end

  it "properly decodes an example of a literal header field with indexing" do
    io = input_fixture "400a 6375 7374 6f6d 2d6b 6579 0d63 7573 746f 6d2d 6865 6164 6572"

    expect { |b| subject.decode io, &b }
      .to yield_with_args("custom-key", "custom-header", anything)
    expect(subject.lookup_table.size).to eq 55
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(1, "custom-key", "custom-header")
  end

  it "properly decodes an example of a literal header field without indexing" do
    io = input_fixture "040c 2f73 616d 706c 652f 7061 7468"

    expect { |b| subject.decode io, &b }
      .to yield_with_args(":path", "/sample/path", anything)
    expect(subject.lookup_table.size).to eq 0
  end

  it "properly decodes an example of a never indexed literal header field" do
    io = input_fixture "1008 7061 7373 776f 7264 0673 6563 7265 74"

    expect { |b| subject.decode io, &b }
      .to yield_with_args("password", "secret", anything)
    expect(subject.lookup_table.size).to eq 0
  end

  it "properly decodes an example of an indexed header field" do
    io = input_fixture "82"

    expect { |b| subject.decode io, &b }
      .to yield_with_args(":method", "GET", anything)
    expect(subject.lookup_table.size).to eq 0
  end

  it "properly decodes a sequence of requests without huffman coding" do
    io = input_fixture """ 8286 8441 0f77 7777 2e65 7861 6d70 6c65
                           2e63 6f6d """

    expect { |b| subject.decode io, &b }
      .to yield_successive_args(
        [":method", "GET", anything],
        [":scheme", "http", anything],
        [":path", "/", anything],
        [":authority", "www.example.com", anything]
      )
    expect(subject.lookup_table.size).to eq 57
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(1, ":authority", "www.example.com")

    io = input_fixture """ 8286 84be 5808 6e6f 2d63 6163 6865 """

    expect { |b| subject.decode io, &b }
      .to yield_successive_args(
        [":method", "GET", anything],
        [":scheme", "http", anything],
        [":path", "/", anything],
        [":authority", "www.example.com", anything],
        ["cache-control", "no-cache", anything]
      )
    expect(subject.lookup_table.size).to eq 110

    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(1, "cache-control", "no-cache")
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(2, ":authority", "www.example.com")

    io = input_fixture """ 8287 85bf 400a 6375 7374 6f6d 2d6b 6579
                           0c63 7573 746f 6d2d 7661 6c75 65 """

    expect { |b| subject.decode io, &b }
      .to yield_successive_args(
        [":method", "GET", anything],
        [":scheme", "https", anything],
        [":path", "/index.html", anything],
        [":authority", "www.example.com", anything],
        ["custom-key", "custom-value", anything]
      )
    expect(subject.lookup_table.size).to eq 164

    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(1, "custom-key", "custom-value")
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(2, "cache-control", "no-cache")
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(3, ":authority", "www.example.com")
  end

  it "properly decodes a sequence of requests with huffman coding" do
    io = input_fixture """ 8286 8441 8cf1 e3c2 e5f2 3a6b a0ab 90f4
                           ff """

    expect { |b| subject.decode io, &b }
      .to yield_successive_args(
        [":method", "GET", anything],
        [":scheme", "http", anything],
        [":path", "/", anything],
        [":authority", "www.example.com", anything]
      )
    expect(subject.lookup_table.size).to eq 57

    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(1, ":authority", "www.example.com")

    io = input_fixture """ 8286 84be 5886 a8eb 1064 9cbf """

    expect { |b| subject.decode io, &b }
      .to yield_successive_args(
        [":method", "GET", anything],
        [":scheme", "http", anything],
        [":path", "/", anything],
        [":authority", "www.example.com", anything],
        ["cache-control", "no-cache", anything]
      )
    expect(subject.lookup_table.size).to eq 110

    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(1, "cache-control", "no-cache")
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(2, ":authority", "www.example.com")

    entry = subject.lookup_table[Hpack::LookupTable::STATIC_TABLE_SIZE + 1]
    expect(entry.name).to eq "cache-control"
    expect(entry.value).to eq "no-cache"

    io = input_fixture """ 8287 85bf 4088 25a8 49e9 5ba9 7d7f 8925
                           a849 e95b b8e8 b4bf  """

    expect { |b| subject.decode io, &b }
      .to yield_successive_args(
        [":method", "GET", anything],
        [":scheme", "https", anything],
        [":path", "/index.html", anything],
        [":authority", "www.example.com", anything],
        ["custom-key", "custom-value", anything]
      )
    expect(subject.lookup_table.size).to eq 164

    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(1, "custom-key", "custom-value")
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(2, "cache-control", "no-cache")
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(3, ":authority", "www.example.com")
  end

  it "properly decodes a sequence of responses without huffman coding" do
    subject.lookup_table.max_size = 256

    io = input_fixture """ 4803 3330 3258 0770 7269 7661 7465 611d
                           4d6f 6e2c 2032 3120 4f63 7420 3230 3133
                           2032 303a 3133 3a32 3120 474d 546e 1768
                           7474 7073 3a2f 2f77 7777 2e65 7861 6d70
                           6c65 2e63 6f6d """

    expect { |b| subject.decode io, &b }
      .to yield_successive_args(
        [":status", "302", anything],
        ["cache-control", "private", anything],
        ["date", "Mon, 21 Oct 2013 20:13:21 GMT", anything],
        ["location", "https://www.example.com", anything]
      )
    expect(subject.lookup_table.size).to eq 222

    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(1, "location", "https://www.example.com")
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(2, "date", "Mon, 21 Oct 2013 20:13:21 GMT")
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(3, "cache-control", "private")
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(4, ":status", "302")

    io = input_fixture """ 4803 3330 37c1 c0bf """

    expect { |b| subject.decode io, &b }
      .to yield_successive_args(
        [":status", "307", anything],
        ["cache-control", "private", anything],
        ["date", "Mon, 21 Oct 2013 20:13:21 GMT", anything],
        ["location", "https://www.example.com", anything]
      )
    expect(subject.lookup_table.size).to eq 222

    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(1, ":status", "307")
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(2, "location", "https://www.example.com")
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(3, "date", "Mon, 21 Oct 2013 20:13:21 GMT")
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(4, "cache-control", "private")

    io = input_fixture """ 88c1 611d 4d6f 6e2c 2032 3120 4f63 7420
                           3230 3133 2032 303a 3133 3a32 3220 474d
                           54c0 5a04 677a 6970 7738 666f 6f3d 4153
                           444a 4b48 514b 425a 584f 5157 454f 5049
                           5541 5851 5745 4f49 553b 206d 6178 2d61
                           6765 3d33 3630 303b 2076 6572 7369 6f6e
                           3d31 """

    expect { |b| subject.decode io, &b }
      .to yield_successive_args(
        [":status", "200", anything],
        ["cache-control", "private", anything],
        ["date", "Mon, 21 Oct 2013 20:13:22 GMT", anything],
        ["location", "https://www.example.com", anything],
        ["content-encoding", "gzip", anything],
        ["set-cookie", "foo=ASDJKHQKBZXOQWEOPIUAXQWEOIU; max-age=3600; version=1", anything]
      )
    expect(subject.lookup_table.size).to eq 215

    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(1, "set-cookie", "foo=ASDJKHQKBZXOQWEOPIUAXQWEOIU; max-age=3600; version=1")
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(2, "content-encoding", "gzip")
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(3, "date", "Mon, 21 Oct 2013 20:13:22 GMT")
  end

  it "properly decodes a sequence of responses with huffman coding" do
    subject.lookup_table.max_size = 256

    io = input_fixture """ 4882 6402 5885 aec3 771a 4b61 96d0 7abe
                           9410 54d4 44a8 2005 9504 0b81 66e0 82a6
                           2d1b ff6e 919d 29ad 1718 63c7 8f0b 97c8
                           e9ae 82ae 43d3 """

    expect { |b| subject.decode io, &b }
      .to yield_successive_args(
        [":status", "302", anything],
        ["cache-control", "private", anything],
        ["date", "Mon, 21 Oct 2013 20:13:21 GMT", anything],
        ["location", "https://www.example.com", anything]
      )
    expect(subject.lookup_table.size).to eq 222

    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(1, "location", "https://www.example.com")
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(2, "date", "Mon, 21 Oct 2013 20:13:21 GMT")
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(3, "cache-control", "private")
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(4, ":status", "302")

    io = input_fixture """ 4883 640e ffc1 c0bf """

    expect { |b| subject.decode io, &b }
      .to yield_successive_args(
        [":status", "307", anything],
        ["cache-control", "private", anything],
        ["date", "Mon, 21 Oct 2013 20:13:21 GMT", anything],
        ["location", "https://www.example.com", anything]
      )
    expect(subject.lookup_table.size).to eq 222

    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(1, ":status", "307")
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(2, "location", "https://www.example.com")
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(3, "date", "Mon, 21 Oct 2013 20:13:21 GMT")
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(4, "cache-control", "private")

    io = input_fixture """ 88c1 6196 d07a be94 1054 d444 a820 0595
                           040b 8166 e084 a62d 1bff c05a 839b d9ab
                           77ad 94e7 821d d7f2 e6c7 b335 dfdf cd5b
                           3960 d5af 2708 7f36 72c1 ab27 0fb5 291f
                           9587 3160 65c0 03ed 4ee5 b106 3d50 07 """

    expect { |b| subject.decode io, &b }
      .to yield_successive_args(
        [":status", "200", anything],
        ["cache-control", "private", anything],
        ["date", "Mon, 21 Oct 2013 20:13:22 GMT", anything],
        ["location", "https://www.example.com", anything],
        ["content-encoding", "gzip", anything],
        ["set-cookie", "foo=ASDJKHQKBZXOQWEOPIUAXQWEOIU; max-age=3600; version=1", anything]
      )
    expect(subject.lookup_table.size).to eq 215

    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(1, "set-cookie", "foo=ASDJKHQKBZXOQWEOPIUAXQWEOIU; max-age=3600; version=1")
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(2, "content-encoding", "gzip")
    expect(subject.lookup_table)
      .to have_dynamic_entry_at_position(3, "date", "Mon, 21 Oct 2013 20:13:22 GMT")
  end

  context 'when dealing with external encoders' do
    IMPLEMENTATIONS = [
      'go-hpack', 'haskell-http2-linear', 'haskell-http2-linear-huffman', 'haskell-http2-naive',
      'haskell-http2-naive-huffman', 'haskell-http2-static', 'haskell-http2-static-huffman',
      'nghttp2', 'nghttp2-16384-4096', 'nghttp2-change-table-size', 'node-http2-hpack',
      'python-hpack'
    ]
    for impl in IMPLEMENTATIONS
      it "properly decodes the hpack-test-case/#{impl} entirely" do
        for story_index in 0..31
          story_index = story_index.to_s.rjust(2, '0')
          story = JSON.parse File.read "./spec/hpack-test-case/#{impl}/story_#{story_index}.json"
          story['cases'].each do |set|
            io = input_fixture set['wire']
            headers = subject.decode io
            h = convert_headers_to_testcase headers
            expect(h).to eq(set['headers'])
          end
        end
      end
    end
  end

  context "when indexed field has index value of 0" do
    it "raises a decoding error" do
      io = input_fixture "80"

      expect { subject.decode io }.to raise_error Hpack::Decoder::ZeroIndexedFieldIndex
    end
  end

  context "when input contains dynamic table size update directive" do
    it "changes lookup table size limit" do
      io = input_fixture "3E"

      expect(subject.decode io).to eq []
      expect(subject.lookup_table.max_size).to eq 30
    end
  end
end
