require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Macker::Search do
  describe "keyword searches" do
    subject { Aji::Macker::Search.new :keywords => [ :video, :games ] }

    it "returns a collection of video hashes" do
      # TODO: Refactor into shared behavior to allow other searches.
      subject.search.should have(100).items
    end
  end

  describe "author searches" do
  end

  describe "#valid_param?" do
    context "when given more than one search param" do
      it "raises a tagged argument error" do
        expect { Aji::Macker::Search.new :keywords => :ice,
          :authors => 'machinima' }.to raise_exception ArgumentError
      end
    end

    context "when given an empty hash" do
      it "raises a tagged argument error" do
        expect { Aji::Macker::Search.new {}
          }.to raise_exception ArgumentError
      end
    end
  end
end

