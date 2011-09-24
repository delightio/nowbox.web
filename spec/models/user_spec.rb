require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::User do
    before :each do
    end

    subject do
      User.create(:name => "John Doe",
        :email => "john@doe.com").tap do |user|
          user.subscribed_list << 1
        end
    end

    it_behaves_like "any redis object model"

    describe ".create" do
      it "creates user channels" do
        Channel::User.should_receive(:create).exactly(3)
        User.any_instance.stub(:save).and_return(true)
        User.create
      end
    end

    describe "#subscribe_featured_channels" do
      it "subscribes to featured channels" do
        featured = (0..2).map { |i| mock "featured_channel", :id => i }
        Aji::Channel.should_receive(:featured).and_return(featured)
        u = User.create
        featured.each { |c| u.subscribed?(c).should be_true }
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
