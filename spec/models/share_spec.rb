require File.expand_path("../../spec_helper", __FILE__)

include Aji

describe Aji::Share, :unit do
  describe "#link" do
    xit "returns the user facing link for this share" do
      subject.stub :id => 1

      subject.link.should == "http://#{Aji.conf['TLD']}/share/1"
    end

    describe "#default_message" do
      subject { Share.new { |s| s.stub :video => stub(:title => "foobar") } }
      it "sets the message to the video title if none is specified" do
        subject.default_message.should == "foobar"
      end
    end
  end
end
