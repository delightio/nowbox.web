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
end
