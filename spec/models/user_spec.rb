require File.expand_path("../../spec_helper", __FILE__)

describe Aji::User do
  describe "#cache_event" do
    it "should cache video id in viewed regardless of event type" do
      user = Factory :user
      [ :view, :share, :upvote, :downvote ].each do |event_type|
        event = Factory :event, :event_type => event_type
        user.cache_event event
        user.viewed_videos.should include event.video
      end
    end

    it "should never fail dequeuing a video" do
      user = Factory :user
      event = Factory :event, :event_type => :dequeue
      lambda { user.cache_event event }.should_not raise_error
      user.queued_videos.should_not include event.video
    end

    it "should dequeue enqueued video" do
      user = Factory :user
      event = Factory :event, :event_type => :enqueue
      user.cache_event event
      user.queued_videos.should include event.video
      event.event_type = :dequeue
      user.cache_event event
      user.queued_videos.should_not include event.video
    end
  end
  
  describe "video_collections" do
    context "when accessing a video collection" do
      it "should return a list of video objects" do
        user = Factory :user
        5.times do
          user.queued_zset[Factory(:video).id] = Time.now.to_i
        end
        user.queued_videos.first.class.should == Aji::Video
      end
    end
  end
  
  describe "channel subscription management" do
    it "should add and remove channel accordingly" do
      user = Factory :user
      channel = Factory :trending_channel
      user.subscribe channel
      user.subscribed_channels.should include channel
      user.unsubscribe channel
      user.subscribed_channels.should_not include channel
    end
  end
  
end
