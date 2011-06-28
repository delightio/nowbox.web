require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Event do
  describe "#create" do
    it "should trigger caching for user" do
      event = Factory :event, :event_type => :view
      event.user.viewed_videos.should include event.video
    end
    
    it "should allow a non 0.0 video_start time" do
      start = rand+0.1
      event = Factory :event, :event_type => :view, :video_start => start
      event.video_start.should == start
    end
  end
end
