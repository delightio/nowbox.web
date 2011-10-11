require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::Authorization do
    let(:given_user) { mock("given user", :identity => stub) }
    let(:auth_hash) do
      { 'provider' => 'twitter', 'uid' => '1234', 'extra' => {} }
    end

    subject { Authorization.new auth_hash, given_user }

    describe "Auth process" do

      context "when the account doesn't exist or has no identity" do
        it "attaches the account to the given users' identity" do
          subject.user.should == given_user
        end
      end

      context "when the account exists and has another identity" do
        let(:found_account) { stub(:identity => mock("identity")) }

        it "merges the given identity with the account's" do
          found_account.identity.should_receive(:merge!).with(
            given_user.identity)
        end
      end
    end

    describe "Deauth process" do
      it "deletes the account from our system"
    end

    describe "#account" do
      let(:account) { stub.as_null_object }

      it "returns a new account instance when none exists" do
        Account::Twitter.stub(:find_by_uid).and_return(nil)
        Account::Twitter.should_receive(:create).and_return(account)

        subject.account
      end

      it "returns an existing account when one is found" do
        Account::Twitter.should_receive(:find_by_uid).with(
          auth_hash['uid']).and_return(account)

        subject.account
      end
    end

  end
end
