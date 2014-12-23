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
  end

  describe "#[]" do
    context "when index is greater than sum of static and dynamic table sizes" do
      it "raises an error" do
        expect { subject[Hpack::LookupTable::STATIC_TABLE_SIZE + 2] }
          .to raise_error Hpack::LookupTable::IndexOutOfBounds
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
