RSpec.describe Hpack::LookupTable do
  describe Hpack::LookupTable::Entry do
    let(:name) { "NAME" }
    let(:value) { "VALUE" }

    subject { Hpack::LookupTable::Entry.new name, value }

    describe "#to_a" do
      it "returns an array with two elements" do
        expect(subject.to_a).to eq [name, value]
      end
    end

    describe "#to_s" do
      it "returns string" do
        expect(subject.to_s).to be_instance_of String
      end
    end

    describe "equality" do
      it "is identity" do
        expect(subject == subject).to be true
        expect(subject === subject).to be true
      end

      it "is strict" do
        e = Hpack::LookupTable::Entry.new name
        expect(subject == e).to be true
        expect(subject === e).to be false
      end
    end
  end

  describe "#[]" do
    context "when index is greater than sum of static and dynamic table sizes" do
      it "raises an error" do
        expect { subject[Hpack::LookupTable::STATIC_TABLE_SIZE + 2] }
          .to raise_error Hpack::LookupTable::IndexOutOfBounds
      end
    end
  end

  describe "#lookup" do
    subject { Hpack::LookupTable.new }
    context "when dynamic table is empty" do
      it 'returns correct indexes for fullindex match' do
        (index, value) = subject.lookup(':method', 'GET')
        expect(index).to be 2
        expect(value).to be_a Hpack::LookupTable::Entry
        expect(value.name).to eq ':method'
        expect(value.value).to eq 'GET'
      end

      it 'returns correct indexes for start keyindex match' do
        (index, value) = subject.lookup(':authority')
        expect(index).to be 1
        expect(value).to be_a Hpack::LookupTable::Entry
        expect(value.name).to eq ':authority'
        expect(value.value).to eq ''
      end

      it 'returns correct indexes for end keyindex match' do
        (index, value) = subject.lookup('www-authenticate')
        expect(index).to be 61
        expect(value).to be_a Hpack::LookupTable::Entry
        expect(value.name).to eq 'www-authenticate'
        expect(value.value).to eq ''
      end
    end

    context "when dynamic table is not empty" do
      before do
        subject << Hpack::LookupTable::Entry.new('header', 'value')
      end

      it 'returns the correct index' do
        (index, value) = subject.lookup('header', 'value')
        expect(index).to be 62
        expect(value).to be_a Hpack::LookupTable::Entry
        expect(value.name).to eq 'header'
        expect(value.value).to eq 'value'
      end
    end
  end

  describe "#to_s" do
    context "when dynamic table is not empty" do
      before do
        subject << Hpack::LookupTable::Entry.new("header", "value")
      end

      it "returns a string" do
        expect(subject.to_s).to be_instance_of String
      end
    end
  end
end
