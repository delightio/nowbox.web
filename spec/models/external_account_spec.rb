require File.expand_path("../../spec_helper", __FILE__)

describe Aji::ExternalAccount do
  describe "#publish" do
    it "should raise an exception unless implemented" do
      ea = Aji::ExternalAccount.new
      expect { ea.publish nil }.to
       raise_error Aji::InterfaceMethodNotImplemented
    end
  end
  describe ".blacklist" do
    it "should blacklist an account" do
      bad_account = Aji::ExternalAccount.create :uid => "someguy"
      bad_account.blacklist
      bad_account.should be_blacklisted
    end
  end
  it "only allows unique external account to be created" do
    uid = random_string
    ea1 = Aji::ExternalAccount.create :uid => uid
    ea1.save.should be_true
    ea2 = Aji::ExternalAccount.find_by_uid uid
    ea2.should_not be_nil
    
    ea3 = Aji::ExternalAccounts::Youtube.create :uid => uid
    ea3.save.should be_true
    ea3.id.should_not == ea1.id
  end
end

describe Aji::ExternalAccounts::Youtube do
  describe "#thumbnail_uri" do
    it "returns a uri from Youtube API"
    it "replaces default blue ghost with first video" do
      pending "Check for default pic url and replace with our own or vid thumb"
    end
  end
end
