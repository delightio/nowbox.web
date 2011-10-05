require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::User do

    subject do
      User.create(:name => "John Doe",
        :email => "john@doe.com").tap do |user|
          user.subscribed_list << 1
        end
    end

    it_behaves_like "any redis object model"

    describe "#create_user_channels" do
      it "creates user channels" do
        Channel::User.should_receive(:create).exactly(3).times
        User.new.send :create_user_channels
      end
    end

    describe "#subscribe_featured_channels" do
      it "subscribes to featured channels based on its region" do
        channel = stub("channel", :id=>5)
        region = stub("region", :featured_channels=>[channel])
        subject.stub(:region).and_return(region)

        subject.should_receive(:subscribe).with(channel)
        subject.subscribe_featured_channels
      end
    end

    describe "#process_event" do
      it "caches video id in viewed regardless of event type except :unfavorite, :enqueue and :dequeue" do
        Aji::Event.video_actions.delete_if{ |t|
          t==:unfavorite || t==:enqueue || t==:dequeue }.each do |action|
            event = Factory :event, :action => action
            event.user.history_channel.content_videos.should include event.video
          end
      end

      it "never fails dequeuing a video" do
        event = nil
        lambda { event = Factory :event, :action => :dequeue }.should_not raise_error
        event.user.queue_channel.content_videos.should_not include event.video
      end

      it "dequeues enqueued video" do
        event = Factory :event, :action => :enqueue
        event.user.queue_channel.content_videos.should include event.video
        dequeued_event = Factory :event, :action => :dequeue,
          :video => event.video, :user => event.user
        event.user.queue_channel.content_videos.should_not include event.video
      end

      it "does not mark a video viewed when queuing" do
        event = Factory :event, :action => :enqueue
        event.user.history_channel.content_videos.should_not include event.video
      end

      it "unfavorites shared videos" do
        user = Factory :user
        video = Factory :video
        event = Factory :event, :action => :share, :user => user, :video => video
        user.favorite_channel.content_videos.should include video
        event = Factory :event, :action => :unfavorite, :user => user, :video => video
        user.favorite_channel.content_videos.should_not include video
      end

      it "subscribes given channel" do
        event = Factory :channel_event, :action => :subscribe
        event.user.subscribed_channels.should include event.channel
      end
      describe "#subscribe" do
        it "ignores already subscribed channels" do
          user = Factory :user
          channel = Factory :channel
          event = Factory :channel_event, :action => :subscribe,
            :channel => channel, :user => user
          user.subscribed_channels.should include channel
          expect { Factory :channel_event,
            :action => :subscribe,
            :channel => channel,
            :user => user }.
            to_not change { user.subscribed_channels.count }
        end
      end

      it "unsubscribes subscribed channel" do
        event = Factory :channel_event, :action => :subscribe
        event.user.subscribed_channels.should include event.channel
        event = Factory :channel_event, :action => :unsubscribe
        event.user.subscribed_channels.should_not include event.channel
      end

      it "does not require video object when sending channel actions" do
        event = Factory :channel_event
        event.video.should be_nil
        event.id.should_not be_nil
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
end
