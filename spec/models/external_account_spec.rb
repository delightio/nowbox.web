require File.expand_path("../../spec_helper", __FILE__)

describe Aji::ExternalAccount do
  describe "#publish" do
    it "should raise an exception unless implemented" do
      ea = Aji::ExternalAccount.new
      expect { ea.publish nil }.to
       raise_error Aji::InterfaceMethodNotImplemented
    end

    describe ".blacklist_id" do
      it "should blacklist an account" do
        bad_account = Aji::ExternalAccount.create
        Aji::ExternalAccount.blacklist_id bad_account.id
        bad_account.should be_blacklisted
      end
    end
  end
end
