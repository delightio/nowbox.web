require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Info do
  describe ".for_device" do
    it "returns a hash of device information" do
      returned = Aji::Info.for_device('ipad')
      [:current_version, :minimum_version, :link].each do |key|
        returned.should have_key key
      end
      [:rel, :url].each do |key|
        returned[:link].should have_key key
      end
    end

    it "raises error if unknown device type is passed in" do
      lambda { Aji::Info.for_device('android') }.should raise_error
    end
  end
end

