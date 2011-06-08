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
    
    it "should never fail dequeuing a video" do
      user = Factory :user
      event = Factory :event, :event_type => :dequeue
      lambda { user.cache_event event }.should_not raise_error
      user.queued.members.should_not include event.video.id.to_s
    end
    
    it "should dequeue enqueued video" do
      user = Factory :user
      event = Factory :event, :event_type => :enqueue
      user.cache_event event
      user.queued.members.should include event.video.id.to_s
      event.event_type = :dequeue
      user.cache_event event
      user.queued.members.should_not include event.video.id.to_s
    end
  end
end
