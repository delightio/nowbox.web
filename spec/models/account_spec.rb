require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Account do
  describe "#publish" do
    it "should raise an exception unless implemented" do
      a = Aji::Account.new
      expect { a.publish nil }.to
       raise_error Aji::InterfaceMethodNotImplemented
    end
  end
  describe ".blacklist" do
    it "should blacklist an account" do
      bad_account = Aji::Account.create :uid => "someguy"
      bad_account.blacklist
      bad_account.should be_blacklisted
    end
  end
end

describe Aji::Account::Youtube do
  describe "#thumbnail_uri" do
    it "returns a uri from Youtube API"
    it "replaces default blue ghost with first video" do
      pending "Check for default pic url and replace with our own or vid thumb"
    end
  end
end
