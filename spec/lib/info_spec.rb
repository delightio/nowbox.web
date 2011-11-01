require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Info do
  describe ".for_device" do
    it "returns a hash of device information" do
      Aji::Info.for_device("ipad").should == {
        :current_version => "1.0.14b10",
        :minimum_version => "1.0.14b10",
        :link => { :rel => "latest", :url => "" }
      }
    end
  end
end
