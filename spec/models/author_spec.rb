require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Author do
  describe "#video_source" do
    it "should write as a symbol" do
      au = Aji::Author.create :screen_name => "nuclearsandwich",
        :video_source => :youtube
      au.read_attribute(:video_source).should == "youtube"
    end

    it "should read as a symbol" do
      au = Aji::Author.create :screen_name => "nuclearsandwich",
        :video_source => :youtube
      au.video_source.should == :youtube
    end
  end
end
