require 'json'

RSpec.describe Hpack::Decoder do
  def input_fixture data
    io = StringIO.new
    io.write [data.gsub(/\s/, "")].pack "H*"
    io.rewind
    io
  end

  def convert_headers_to_testcase(headers)
    headers.map {|h| {h[0] => h[1]}}
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

end