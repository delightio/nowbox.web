require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Account do
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

