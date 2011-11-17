require File.expand_path("../../spec_helper", __FILE__)

include Aji

describe Aji::Share, :unit do
  let(:twitter_account) { stub.as_null_object }
  let(:user) do
    u = User.create
    u.stub :twitter_account => twitter_account
    u
  end
  let(:video) { Video.create :source => 'youtube',
    :external_id => "3307vMsCG0I" }
  let(:channel) { Channel.create }
  let(:network) { "twitter" }
  subject { Share.create user: user,
    video: video, channel: channel, network: network }

  describe "#link" do
    it "returns the user facing link for this share" do
      subject.link.should == "http://#{Aji.conf['TLD']}/shares/#{subject.id}"
    end
  end

  describe "#default_message" do
    it "sets the message to the video title if none is specified" do
      video.stub :title => "blah"
      subject.default_message.should == video.title
    end
  end

  describe "#publisher" do
    it "returns the account which publishes the share" do
      subject.publisher == twitter_account
    end
  end

  describe "#publish" do
    it "calls publish in background after object creation" do
      twitter_account.should_receive :background_publish
      subject
    end
  end

end
