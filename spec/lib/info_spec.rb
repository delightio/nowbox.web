require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Info do
  describe ".for_device" do
    it "returns a hash of device information" do
      Aji::Info.for_device("ipad").should == {
        :current_version => "1.0.18",
        :minimum_version => "1.0.18",
        :link => { :rel => "latest",
                   :url => "http://tflig.ht/tb9sfs" }
      }
    end
  end
end

