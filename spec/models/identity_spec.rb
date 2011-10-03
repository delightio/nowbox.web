require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::Identity, :unit => true do
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
  end
end


