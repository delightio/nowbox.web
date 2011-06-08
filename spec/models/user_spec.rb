require File.expand_path("../../spec_helper", __FILE__)

describe Aji::User do
  describe "#cache_event" do
    it "should cache video id in viewed regardless of event type" do
      user = Factory :user
      [ :view, :share, :upvote, :downvote ].each do |event_type|
        event = Factory :event, :event_type => event_type
        user.cache_event event
        user.viewed.members.should include event.video.id.to_s
      end
    end
  end
end
