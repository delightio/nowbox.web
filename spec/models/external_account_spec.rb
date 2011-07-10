require File.expand_path("../../spec_helper", __FILE__)

describe Aji::ExternalAccount do
  describe "#publish" do
    it "should raise an exception unless implemented" do
      ea = Aji::ExternalAccount.new
      expect { ea.publish nil }.to
       raise_error Aji::InterfaceMethodNotImplemented
    end
  end
end
