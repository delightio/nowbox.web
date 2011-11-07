require File.expand_path("../../spec_helper", __FILE__)

include Aji

describe Aji::Share, :unit do
  let(:user) { User.create }
  let(:video) { Video.create :source => 'youtube',
    :external_id => "3307vMsCG0I" }
  let(:network) { "twitter" }
  subject { Share.create user: user, video: video, network: network }

  describe "#link" do
    it "returns the user facing link for this share" do
      subject.link.should == video.source_link
    end
  end

  describe "#default_message" do
    it "sets the message to the video title if none is specified" do
      video.stub :title => "blah"
      subject.default_message.should == video.title
    end
  end

  describe "#publisher" do
    let(:publisher) { mock }
    it "returns the account which publishes the share" do
      subject.user.stub :twitter_account => publisher
      subject.publisher == publisher
    end
  end

  describe ".from_event" do
    let(:user) { User.new }
    let(:video) { Video.new source: :youtube, title: "Video" }
    let(:network) { "twitter" }
    let(:event) { stub :video => video, :user => user, :reason => "foobar" }
    subject { Share.from_event event, network }

    its(:user) { should == user }
    its(:video) { should == video }
    its(:message) { should == event.reason }
    its(:network) { should == network }
  end
end
