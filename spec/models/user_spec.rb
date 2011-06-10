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
    
    it "should not mark a video viewed when queuing" do
      user = Factory :user
      event = Factory :event, :event_type => :enqueue
      user.cache_event event
      user.viewed_videos.should_not include event.video
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
  
  context "channel subscription management" do
    it "should add and remove channel accordingly" do
      user = Factory :user
      channel = Factory :trending_channel
      user.subscribe channel
      user.subscribed_channels.should include channel
      user.unsubscribe channel
      user.subscribed_channels.should_not include channel
    end
    it "should move given channel into corresponding position" do
      n = 10
      user = Factory :user
      channels = []
      n.times do |n|
        channel = Factory :channel
        channels << channel
        user.subscribe channel
      end
      user.subscribed_channels.size.should == n
      old_position = rand(n)
      user.subscribed_channels[old_position].should == channels[old_position]
      begin
        args = {:new_position => rand(n)}
      end while args[:new_position]==old_position
      user.arrange channels[old_position], args
      user.subscribed_channels.size.should == n
      user.subscribed_channels[old_position].should_not == channels[old_position]
      user.subscribed_channels[args[:new_position]].should == channels[old_position]
    end
  end
  
  describe "#serializable_hash" do
    it "should return subscribed channel list" do
      user = Factory :user
      channel_ids = Set.new
      5.times do |n|
        channel = Factory :channel_with_videos
        channel_ids << channel.id
        user.subscribe channel
      end
      user.serializable_hash["channel_ids"].should == user.subscribed_list.values
    end
  end
  
end
