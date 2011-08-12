require File.expand_path("../../spec_helper", __FILE__)

describe Aji::User do

  describe "#process_event" do
    it "caches video id in viewed regardless of event type except :enqueue and :dequeue" do
      Aji::Event.video_actions.delete_if{|t| t==:enqueue||t==:dequeue}.each do |action|
        event = Factory :event, :action => action
        event.user.viewed_videos.should include event.video
      end
    end

    it "never fails dequeuing a video" do
      event = nil
      lambda { event = Factory :event, :action => :dequeue }.should_not raise_error
      event.user.queued_videos.should_not include event.video
    end

    it "dequeues enqueued video" do
      event = Factory :event, :action => :enqueue
      event.user.queued_videos.should include event.video
      dequeued_event = Factory :event, :action => :dequeue,
        :video => event.video, :user => event.user
      event.user.queued_videos.should_not include event.video
    end

    it "does not mark a video viewed when queuing" do
      event = Factory :event, :action => :enqueue
      event.user.viewed_videos.should_not include event.video
    end

    it "subscribes given channel"
    it "unsubscribes subscribed channel"
    it "does not require video object when sending channel actions"

  end

  describe "video_collections" do
    context "when accessing a video collection" do
      it "should return a list of video objects" do
        user = Factory :user_with_viewed_videos
        user.viewed_videos.first.class.should == Aji::Video
      end
    end
  end

  describe "#serializable_hash" do
    it "should include a list of subscribed channel ids" do
      user = Factory :user
      5.times do |n|
        channel = Factory :channel
        event = Factory :channel_event, :action => :subscribe,
          :user => user, :channel => channel
      end
      user.serializable_hash["subscribed_channel_ids"].should == user.subscribed_list.values
    end
  end

end
