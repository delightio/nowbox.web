require File.expand_path("../../spec_helper", __FILE__)

include Aji

describe Aji::Authorization do
  let(:given_identity) { stub :user => stub, :save => true }
  subject { Authorization.new account, given_identity }

  describe "#grant!" do
    let(:account) do
      OpenStruct.new(:identity => nil).tap do |a|
        a.stub :save => true
        a.stub :authorize! => true
      end
    end

    context "when the account is not associated with an identity" do
      it "assigns the given identity to the account" do
        expect{ subject.grant! }.to change{ account.identity }.from(nil).to(
          given_identity)
      end
    end

    context "when the account identity matches the given identity" do
      let(:account) do
        mock "account", :identity => given_identity, :save => true,
          :authorize! => true
      end

      it "sets the user to the given identity's user" do
        expect{ subject.grant! }.to change{ subject.user }.from(nil).to(
          given_identity.user)
      end
    end

    context "when the account identity is not the given identity" do
      let(:account) do
        mock "account", :identity => stub(:merge! => true, :user => stub,
          :save => true), :save => true, :authorize! => true
      end

      it "merges the given identity into the account identity" do
        account.identity.should_receive(:merge!).with(given_identity)

        subject.grant!
      end

      it "sets the user to the account identity's user" do
        expect{ subject.grant! }.to change{ subject.user }.from(nil).to(
          account.identity.user)
      end
    end

    it "authorizes the user to interact with this account" do
      account.should_receive(:authorize!).with(given_identity.user)

      subject.grant!
    end
  end

  describe "#deauthorize!" do
    let!(:account) do
      stub :identity => stub, :user => stub, :deauthorize! => true,
        :save => true
    end

    subject { Authorization.new account, account.identity }

    it "deauthorizes the given account" do
      account.should_receive(:deauthorize!)

      subject.deauthorize!
    end

    it "sets the user to the given identity's user" do
      expect{ subject.deauthorize! }.to change{ subject.user }.from(nil).to(
        account.user)
    end
  end
end

