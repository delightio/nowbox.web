require File.expand_path("../../spec_helper", __FILE__)

include Aji
describe Aji::Identity, :unit => true do
  describe "#merge!" do
    subject do
      Identity.new.tap do |i|
        i.stub :accounts => []
        i.stub :user => mock("user", :merge! => true)
      end
    end

    let(:other_identity) do
      Identity.new.tap do |i|
        i.stub :accounts => [mock("other account")]
        i.stub :user => mock("other user")
        i.stub :destroy => i
      end
    end

    it "merges the user associated with the other identity into its own" do
      subject.user.should_receive(:merge!).with(other_identity.user)
      subject.merge! other_identity
    end

    it "adds accounts from the other identity to this one" do
      subject.merge! other_identity
      other_identity.accounts.each do |a|
        subject.accounts.should include a
      end
    end

    it "preserves accounts that were already in the identity" do
      subject.accounts << (existing_account = mock("existing account"))
      subject.merge! other_identity
      subject.accounts.should include existing_account
    end

    it "destroys the merged in identity when complete" do
      other_identity.should_receive(:destroy)

      subject.merge! other_identity
    end
  end

  describe "#social_channel_ids" do
    let(:identity_with_nothing) do
      Identity.new.tap do |i|
        i.stub :facebook_account => nil
        i.stub :twitter_account => nil
      end
    end

    let(:identity_with_facebook) do
      Identity.new.tap do |i|
        i.stub :facebook_account => mock("fb", :stream_channel_id => 1)
        i.stub :twitter_account => nil
      end
    end

    let(:identity_with_twitter) do
      Identity.new.tap do |i|
        i.stub :twitter_account => mock("twitter", :stream_channel_id => 1)
        i.stub :facebook_account => nil
      end
    end

    let(:identity_with_both) do
      Identity.new.tap do |i|
        i.stub :facebook_account => mock("fb", :stream_channel_id => 1)
        i.stub :twitter_account => mock("twitter", :stream_channel_id => 2)
      end
    end

    context "when neither is present" do
      it "returns an empty hash" do
        identity_with_nothing.social_channel_ids.should == Hash.new
      end
    end

    context "when either a facebook or twitter account is present" do
      it "returns a JSONable hash of with the id" do
        identity_with_twitter.social_channel_ids.should == {
          'twitter_channel_id' => 1 }

          identity_with_facebook.social_channel_ids.should == {
            'facebook_channel_id' => 1 }
      end
    end

    context "when both are present" do
      it "returns a JSONable hash of channel ids" do
        identity_with_both.social_channel_ids.should == {
          'facebook_channel_id' => 1,
          'twitter_channel_id' => 2
        }
      end
    end
  end

  describe "#social_channels" do
    context "with no accounts" do
      it "returns an empty array" do
        subject.social_channels.should be_empty
      end
    end

    context "with accounts" do
      it "returns a single element array" do
        subject.stub(:accounts => [
          mock("twitter", :stream_channel => stub),
          mock("facebook", :stream_channel => stub)
        ])

        subject.social_channels.should have(2).channels
      end
    end
  end

  describe "#facebook_account" do
    it "gets the identity's facebook account from accounts list" do
      subject.accounts.should_receive(:where).with(
        :type => 'Aji::Account::Facebook').and_return(
          (accounts = stub).should_receive(:first) && accounts)

          subject.facebook_account
    end
  end

  describe "#twitter_account" do
    it "gets the identity's twitter account from accounts list" do
      subject.accounts.should_receive(:where).with(
        :type => 'Aji::Account::Twitter').and_return(
          (accounts = stub).should_receive(:first) && accounts)

          subject.twitter_account
    end
  end

  describe "#account_info" do
    subject { Identity.new { |i| i.stub :accounts => [account] } }
    let(:account) do
      mock("youtube account", :provider => "Youtube", :uid => "nuclearsandwich",
        :username => "nuclearsandwich", :synchronized_at => 1.hour.ago)
    end

    it "returns a hash of information on authorized accounts" do
      subject.account_info.should == [{
        'provider' => account.provider,
        'uid' => account.uid,
        'username' => account.username,
        'synchronized_at' => account.synchronized_at.to_i
      }]
    end

    it "doesn't cast nil to 0" do
      pending "iOS wants nil to be 0"

      account.stub :synchronized_at => nil

      subject.account_info.first['synchronized_at'].should be_nil
    end
  end

  describe "#hook" do
    subject { Identity.new { |i| i.stub :accounts => accounts } }

    let(:accounts) { [youtube_account, facebook_account, twitter_account] }
    let(:youtube_account) do
      mock "youtube account", :on_favorite => true, :on_unfavorite => true,
        :on_subscribe => true, :on_unsubscribe => true, :on_enqueue => true,
        :on_dequeue => true
    end
    let(:facebook_account) { mock "facebook account", :on_favorite => true }
    let(:twitter_account) do
      mock "twitter account", :on_favorite => true, :on_subscribe => true
    end
    let(:video) { mock "video" }
    let(:channel) { mock "channel" }

    it "delegates to all accounts that respond to the hook" do
      accounts.each{ |a| a.should_receive(:on_favorite).with(video) }
      [youtube_account, twitter_account].each do |a|
        a.should_receive(:on_subscribe).with(channel)
      end
      youtube_account.should_receive(:on_enqueue).with(video)

      subject.hook :favorite, video
      subject.hook :subscribe, channel
      subject.hook :enqueue, video
    end

    it "doesn't call hooks on accounts when they aren't implemented" do
      facebook_account.tap do |a|
        a.should_not_receive(:on_subscribe)
        a.should_not_receive(:on_enqueue)
        # Since setting the expectation messes with respond_to? we stub it.
        a.stub(:respond_to?).with(:on_subscribe).and_return(false)
        a.stub(:respond_to?).with(:on_enqueue).and_return(false)
        a.stub(:respond_to?).with(:on_favorite).and_return(true)
      end

      twitter_account.tap do |a|
        a.should_not_receive(:on_enqueue)
        # Since setting the expectation messes with respond_to? we stub it.
        a.stub(:respond_to?).with(:on_enqueue).and_return(false)
        a.stub(:respond_to?).with(:on_subscribe).and_return(true)
        a.stub(:respond_to?).with(:on_favorite).and_return(true)
      end

      subject.hook :favorite, video
      subject.hook :subscribe, channel
      subject.hook :enqueue, video
    end
  end
end

