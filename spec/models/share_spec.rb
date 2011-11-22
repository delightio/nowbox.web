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

  describe ".create" do
    let(:valid_publisher) { stub :authorized? => true,
      :background_publish => nil }
    it "validates if publisher is authorized" do
      user.stub :twitter_account => valid_publisher
      subject.should be_valid
    end

    let(:no_token) { stub :authorized? => false,
      :has_token? => false }
    it "is invalid with invalid token" do
      user.stub :twitter_account => no_token
      subject.should_not be_valid
      subject.errors.should include :publisher => ["has no token."]
    end

    let(:expired_token) { stub :authorized? => false,
      :has_token? => true }
    it "reports expired token" do
      user.stub :twitter_account => expired_token
      subject.should_not be_valid
      subject.errors.should include :publisher => ["has an expired token."]
    end
  end

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
    it "calls publish in background after object creation" do
      twitter_account.should_receive :background_publish
      subject
    end
  end

end
