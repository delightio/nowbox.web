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

    describe "#publish" do
      it "should raise an exception unless implemented" do
        expect { subject.publish nil }.to(
          raise_error Aji::InterfaceMethodNotImplemented)
      end
    end

    describe "#refresh_content" do
      it "raises an exception unless implemented" do
        expect { subject.refresh_content }.to(
          raise_error Aji::InterfaceMethodNotImplemented)
      end
    end

    describe "#blacklist" do
      it "should blacklist an account" do
        bad_account = Aji::Account.create :uid => "someguy"
        bad_account.blacklist
        bad_account.should be_blacklisted
      end
    end

    describe ".from_param" do
      it "parses username and provider from a specialized param string" do
        param_string = "nuclearsandwich@youtube"
        Aji::Account.from_param(param_string).
          should == [ "nuclearsandwich", "youtube" ]
      end
    end
  end
end
