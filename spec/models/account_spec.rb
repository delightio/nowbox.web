require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Account do
  describe "#profile_uri, #thumbnail_uri, #description" do
    it "raise an exception unless implemented" do
      [:profile_uri, :thumbnail_uri, :description].each do |m|
        expect { subject.send m }.to(
          raise_error Aji::InterfaceMethodNotImplemented)
      end
    end
  end

  describe "#publish" do
    it "raises an exception unless implemented" do
      expect { subject.publish nil }.to
        raise_error Aji::InterfaceMethodNotImplemented
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

