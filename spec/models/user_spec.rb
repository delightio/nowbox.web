require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::User do
    subject do
      User.new.tap do |user|
        user.stub(:id => 1)
        user.subscribed_list << 1
      end
    end

    it_behaves_like "any redis object model"

    describe "#create_user_channels" do
      it "creates user channels" do
        Channel::User.should_receive(:create).exactly(3).times
        subject.send :create_user_channels
      end
    end

    describe "#subscribe_featured_channels" do
      let(:featured_channels) do
        (1..3).map do |i|
          mock("channel", :id => i)
        end
      end

      let(:region) { mock "region", :featured_channels => featured_channels }

      it "subscribes the user to the featured channels" do
        subject.stub :region => region
        subject.subscribe_featured_channels
        featured_channels.each { |c| subject.should be_subscribed(c) }
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
            :user => user }.to_not change { user.subscribed_channels.count }
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
      it "includes a list of subscribed channel ids" do
        user = Factory :user
        5.times do |n|
          channel = Factory :channel
          event = Factory :channel_event, :action => :subscribe,
            :user => user, :channel => channel
        end
        user.serializable_hash["subscribed_channel_ids"].should == user.subscribed_list.values
      end
    end

    describe "#merge" do
      let(:other_user) do
        User.new.tap do |u|
          u.stub :id => 2
          u.stub(:subscribed_channels => (4..7).map do |i|
            mock("channel", :id => i).tap do |c|
              Channel.stub(:find_by_id).with(c.id).and_return(c)
            end
          end)
        end
      end

      let!(:previously_subscribed_channels) do
        (1..3).map do |i|
          mock("channel", :id => i).tap do |c|
            subject.subscribe c
            Channel.stub(:find_by_id).with(c.id).and_return(c)
          end
        end
      end

      # TODO: Should we provide a facility to subscribe without instantiating
      # a channel?
      it "combines subscribed channels from both" do
        subject.merge other_user

        other_user.subscribed_channels.each do |c|
          subject.should be_subscribed(c)
        end
      end

      it "preserves channels the user was already subscribed to" do
        subject.merge other_user

        previously_subscribed_channels.each do |c|
          subject.should be_subscribed(c)
        end
      end

      it "combines history, favorites, and queues of the two users"

      it "takes email and name from whichever user is populated most recently"

      it "keeps the identity of the local (implicit) user"
    end
  end
end
