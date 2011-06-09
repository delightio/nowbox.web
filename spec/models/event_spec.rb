require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Event do
  describe "#create" do
    it "should trigger caching for user" do
      event = Factory :event, :event_type => :view
      event.user.viewed_videos.should include event.video
    end
  end
end
