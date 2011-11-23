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

  describe "#publisher" do
    it "returns the account which publishes the share" do
      subject.publisher == twitter_account
    end
  end

  describe "#publish" do
    it "calls publish before object creation" do
      twitter_account.should_receive(:publish).with(subject)
      subject
    end
  end

  describe ".create" do
    it "rolls back if publish fails" do
      twitter_account.should_receive(:publish).and_raise(stub)
      subject.should be_new_record
    end

    it "succeeds if publish succeeded" do
      subject.should_not be_new_record
    end
  end

end
