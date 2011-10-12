require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::Authorization do
    let(:given_identity) { mock("identity", :user => stub) }
    let(:auth_hash) do
      { 'provider' => 'twitter', 'uid' => '1234', 'extra' => {} }
    end

    subject { Authorization.new auth_hash, given_identity }

    context "during authorization" do

    end

    context "during deauthorization" do
    end

    describe "#account" do
      let(:account) { stub.as_null_object }

      it "returns a new account instance when none exists" do
        Account::Twitter.stub(:find_by_uid).and_return(nil)
        Account::Twitter.should_receive(:create)

        subject.account
      end

      it "returns an existing account when one is found" do
        Account::Twitter.should_receive(:find_by_uid).with(
          auth_hash['uid']).and_return(account)

        subject.account
      end
    end

    describe "#user" do
      context "when the account is new" do
        let(:account) { stub(:identity => given_identity) }

        it "returns the user from the given identity" do
          Account::Twitter.stub(:find_by_uid).and_return(nil)
          Account::Twitter.stub(:create).and_return(account)

          subject.user.should == given_identity.user
        end
      end

      context "when the account has an existing identity" do
        let(:existing_user) { stub }
        let(:account) do
          stub(:identity => mock("existing identity", :user => existing_user,
           :merge! => true), :update_from_auth_info => true)
        end

        it "merges the given identity with the account's" do
          Account::Twitter.should_receive(:find_by_uid).with(
            auth_hash['uid']).and_return(account)

          account.identity.should_receive(:merge!).with(given_identity)

          subject.user
        end

        it "returns the user associated with the account identity" do
          Account::Twitter.should_receive(:find_by_uid).with(
            auth_hash['uid']).and_return(account)

          subject.user.should == existing_user
        end
      end
    end
  end
end
