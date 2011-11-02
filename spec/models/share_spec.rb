require File.expand_path("../../spec_helper", __FILE__)

include Aji

describe Aji::Share, :unit do
  describe "#link" do
    xit "returns the user facing link for this share" do
      subject.stub :id => 1

      subject.link.should == "http://#{Aji.conf['TLD']}/share/1"
    end
  end

  describe "#default_message" do
    subject { Share.new { |s| s.stub :video => stub(:title => "foobar") } }
    it "sets the message to the video title if none is specified" do
      subject.default_message.should == "foobar"
    end
  end

  describe ".from_event" do
    let(:user) { User.new }
    let(:video) { Video.new source: :youtube, title: "Video" }
    let(:event) { stub :video => video, :user => user }
    subject { Share.from_event event }

    its(:user) { should == user }
    its(:video) { should == video }
    its(:message) { should == video.title }
  end
end
