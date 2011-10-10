require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::Account do
    subject do
      # We tap the account to return it after pushing content to its Redis
      # Objects so we can test the cleanup code.
      Account.create(:username => "foobar", :uid => "1234").tap do |account|
        account.content_zset[1] = 1
        account.influencer_set << 1
      end
    end

    it_behaves_like "any redis object model"

    describe ".from_param" do
      it "parses username and provider from a specialized param string" do
        param_string = "nuclearsandwich@youtube"
        Aji::Account.from_param(param_string).
          should == [ "nuclearsandwich", "youtube" ]
      end
    end

    describe "#blacklisted_videos" do
      it "returns the previously blacklisted videos" do
        pending "#blacklisted_videos is an AR call but we should test it."
      end
    end

    describe "#blacklist_repeated_offender" do
      it "blacklists self if it has too many blacklisted videos" do
        subject.stub(:blacklisted_videos).and_return(Array.new(3, mock))
        subject.should_receive(:blacklist).once
        subject.blacklist_repeated_offender
      end
    end

  end
end
