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
      it "raises an exception unless implemented" do
        expect { subject.publish nil }.to
        raise_error Aji::InterfaceMethodNotImplemented
      end
    end

    describe "#profile_uri, #thumbnail_uri, #description" do
      it "raise an exception unless implemented" do
        [:profile_uri, :thumbnail_uri, :description].each do |m|
          expect { subject.send m }.to(
            raise_error Aji::InterfaceMethodNotImplemented)
        end
      end
    end
  end

  describe "#refresh_content" do
    subject do
      # We tap the account to return it after pushing content to its Redis
      # Objects so we can test the cleanup code.
      Account.create(:username => "foobar", :uid => "1234").tap do |account|
        account.content_zset[1] = 1
        account.influencer_set << 1
      end
    end
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

  describe ".create_all_if_valid" do

    it "returns empty array if given invalid username" do
      bad_username = random_string
      Account.stub(:exiting?).with(bad_username).
        and_return(false)
      new_accounts = Account.create_all_if_valid bad_username
      new_accounts.should be_empty
    end

    it "returns new objects if given valid username" do
      name = random_string

      account = mock("account", :id => 1)
      account.should_receive(:existing?).and_return(true)
      account.should_receive(:save).and_return(true)

      descendant = mock("Account Subtype")
      descendant.should_receive(:new).with(:uid=>name).
        and_return(account)
      Account.should_receive(:descendants).and_return([descendant])

      new_accounts = Account.create_all_if_valid name
      new_accounts.should == [account]
    end

  end

end
