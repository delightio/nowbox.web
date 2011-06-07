require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Channel do
  describe "#populate" do
    it "raises an exception unless overridden." do
      c = Aji::Channel.new(:title => "foo")
      expect { c.populate }.to raise_error Aji::InterfaceMethodNotImplemented
    end
  end

end
