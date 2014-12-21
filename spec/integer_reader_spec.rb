RSpec.describe Hpack::IntegerReader do
  let(:io) { StringIO.new }

  it "properly decodes a first example of an encoded integer value" do
    header_byte = 0b0000_1010

    expect(subject.read length: 5, input: io, start_with: header_byte)
      .to eq 10
  end

  it "properly decodes a second example of an encoded integer value" do
    header_byte = 0b0001_1111
    io.write [
      0b1001_1010,
      0b0000_1010
    ].pack "C*"
    io.rewind

    expect(subject.read length: 5, input: io, start_with: header_byte)
      .to eq 1337
  end

  it "properly decodes a third example of an encoded integer value" do
    header_byte = 0b0010_1010

    expect(subject.read length: 8, input: io, start_with: header_byte)
      .to eq 42
  end

end
