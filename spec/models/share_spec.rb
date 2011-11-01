require File.expand_path("../../spec_helper", __FILE__)

include Aji

describe Aji::Share, :unit do
  describe "#link" do
    xit "returns the user facing link for this share" do
      subject.stub :id => 1

      subject.link.should == "http://#{Aji.conf['TLD']}/share/1"
    end
  end
end
