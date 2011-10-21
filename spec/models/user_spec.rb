require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::User do
    subject do
      User.new.tap do |u|
        u.stub(:id => 1)
        u.subscribed_list << 1
        u.name = "George"
        u.email = "george@thejungle.com"
        u.stub(:history_channel => stub(:merge! => true))
        u.stub(:favorite_channel => stub(:merge! => true))
        u.stub(:queue_channel => stub(:merge! => true))
      end
    end

    it_behaves_like "any redis object model" do
      subject do
        User.new.tap do |u|
          u.stub(:id => 1)
          u.subscribed_list << 1
          u.name = "George"
          u.email = "george@thejungle.com"
          u.stub(:history_channel).as_null_object
          u.stub(:favorite_channel).as_null_object
          u.stub(:queue_channel).as_null_object
        end
      end
    end

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

      it "does not require video object when sending channel actions" do
        event = Factory :channel_event
        event.video.should be_nil
        event.id.should_not be_nil
      end
    end

    describe "channel subscriptions" do
      let(:channel) { mock "channel", :id => 12 }

      describe "#social_channels" do
        let(:social_channels) { (0..2).map{ |i| mock "channel", :id => i } }
        let(:nonexistant_channel) { mock "channel", :id => 10 }

        subject do
          User.new do |u|
            u.stub :id => 1
            u.stub :social_channel_list => social_channels.map(&:id)
          end
        end

        before do
          Channel.stub(:find_by_id).with(nonexistant_channel.id).and_return(nil)

          social_channels.each do |c|
            Channel.stub(:find_by_id).with(c.id).and_return(c)
          end
        end

        it "returns a list of channels whose ids in social_channel_list" do
          subject.social_channels.should == social_channels
        end

        it "ignores channel ids that don't resolve" do
          subject.social_channel_list << nonexistant_channel.id

          subject.social_channels.should == social_channels
        end

        it "removes empty channels when they're found" do
          subject.social_channel_list << nonexistant_channel.id
          subject.should_receive :remove_missing_channels

          subject.social_channels.should == social_channels
        end
      end

      describe "#subscribed_channels" do
        let(:subscribed_channels) { (0..2).map{ |i| mock "channel", :id => i } }
        let(:nonexistant_channel) { mock "channel", :id => 10 }

        subject do
          User.new do |u|
            u.stub :id => 1
            u.stub :subscribed_list => subscribed_channels.map(&:id)
          end
        end

        before do
          Channel.stub(:find_by_id).with(nonexistant_channel.id).and_return(nil)

          subscribed_channels.each do |c|
            Channel.stub(:find_by_id).with(c.id).and_return(c)
          end
        end

        it "returns a list of channels whose ids in subscribed_list" do
          subject.subscribed_channels.should == subscribed_channels
        end

        it "ignores channel ids that don't resolve" do
          subject.subscribed_list << nonexistant_channel.id

          subject.subscribed_channels.should == subscribed_channels
        end

        it "removes empty channels when they're found" do
          subject.subscribed_list << nonexistant_channel.id
          subject.should_receive :remove_missing_channels

          subject.subscribed_channels.should == subscribed_channels
        end
      end

      describe "#subscribed?" do
        specify "true when video is in subscribed_list" do
          subject.subscribed_list << channel.id

          subject.should be_subscribed(channel)
        end

        specify "false otherwise" do
          subject.should_not be_subscribed(channel)
        end
      end

      describe "#subscribed_social?" do
        specify "true when video is included in social_channel_list" do
          subject.social_channel_list << channel.id

          subject.should be_subscribed_social(channel)
        end

        specify "false otherwise" do
          subject.should_not be_subscribed_social(channel)
        end
      end

      describe "#subscribe" do
        it "puts the channel id into the user's social_channel_list" do
          subject.subscribed_list.should_receive(:<<).with(channel.id)

          subject.subscribe channel
        end

        it "doesn't add videos that are already subcribed" do
          subject.stub(:subscribed?).with(channel).and_return(true)
          subject.subscribed_list.should_not_receive(:<<).with(channel.id)

          subject.subscribe channel
        end

        it "returns true when the video is succesfully subscribed" do
          subject.subscribe(channel).should be_true
        end

        it "returns false when the video is not subscribed" do
          subject.stub(:subscribed?).with(channel).and_return(false)

          subject.subscribe(channel).should be_false
        end
      end

      describe "#subscribe_social" do
        it "puts the channel id into the user's social_channel_list" do
          subject.social_channel_list.should_receive(:<<).with(channel.id)

          subject.subscribe_social channel
        end

        it "doesn't add videos that are already subcribed" do
          subject.stub(:subscribed_social?).with(channel).and_return(true)
          subject.social_channel_list.should_not_receive(:<<).with(channel.id)

          subject.subscribe_social channel
        end

        it "returns true when the video is succesfully subscribed" do
          subject.subscribe_social(channel).should be_true
        end

        it "returns false when the video is not subscribed" do
          subject.stub(:subscribed_social?).with(channel).and_return(false)

          subject.subscribe_social(channel).should be_false
        end
      end

      describe "#unsubscribe" do
        it "deletetes the channel id from the subscribed_list" do
          subject.subscribed_list.should_receive(:delete).with(
            channel.id)

            subject.unsubscribe channel
            subject.subscribed_list.should_not include channel.id
        end

        specify "returns true when the channel is no longer in the list" do
          subject.subscribed_list << channel.id

          subject.unsubscribe(channel).should be_true
        end

        specify "returns false when the channel is still subscribed" do
          subject.stub(:subscribed?).with(channel).and_return(true)

          subject.unsubscribe(channel).should be_false
        end
      end

      describe "#unsubscribe_social" do
        it "deletetes the channel id from the social_channel_list" do
          subject.social_channel_list.should_receive(:delete).with(
            channel.id)

            subject.unsubscribe_social channel
            subject.social_channel_list.should_not include channel.id
        end

        specify "returns true when the channel is no longer in the list" do
          subject.social_channel_list << channel.id

          subject.unsubscribe_social(channel).should be_true
        end

        specify "returns false when the channel is still subscribed" do
          subject.stub(:subscribed_social?).with(channel).and_return(true)

          subject.unsubscribe_social(channel).should be_false
        end
      end
    end

    describe "#user_channels" do
      it "returns all user channels" do
        pending "Current name conflict with method"
      end
    end

    describe "#display_channels" do
      let(:user_channels) { [ mock("fav channel"), mock("queue_channel") ] }
      let(:subscribed_channels) { [ mock("hilarious channel") ] }
      let(:social_channels) { [ mock("fb channel"), mock("twitter channel") ] }

      it "returns an array of of all displayable channels" do
        subject.stub(:user_channels).and_return(user_channels)
        subject.stub(:subscribed_channels).and_return(subscribed_channels)
        subject.stub(:social_channels).and_return(social_channels)
        subject.display_channels.should == user_channels + social_channels +
          subscribed_channels
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
        user.serializable_hash["subscribed_channel_ids"].should ==(
          user.subscribed_list.values)
      end
    end

    describe "#remove_missing_channels" do
      let(:valid_ids) do
        [1, 2].each { |i| Channel.stub(:find_by_id).with(i).and_return(true) }
      end

      let(:invalid_ids) do
        [3, 4].each { |i| Channel.stub(:find_by_id).with(i).and_return(nil) }
      end

      subject do
        User.new do |u|
          u.stub :id => 1
          (valid_ids + invalid_ids).each do |id|
            u.subscribed_list << id
          end
        end
      end

      it "doesn't remove valid channels" do
        valid_ids.each do |id|
          subject.subscribed_list.should_not_receive(:delete).with(id)
        end

        subject.send :remove_missing_channels
      end

      it "deletes missing ids from subscribed_list" do
        invalid_ids.each do |id|
          subject.subscribed_list.should_receive(:delete).with(id)
        end

        subject.send :remove_missing_channels
      end

      it "doesn't hit the database for known good video ids" do
        valid_ids.each do |id|
          Video.should_not_receive(:find_by_id).with(id)
        end

        subject.send :remove_missing_channels, valid_ids
      end
    end

    describe "#merge!" do
      let(:other_user) do
        User.new.tap do |u|
          u.stub :id => 2
          u.name = "Tarzan"
          u.email = "tarzan@apes.gov"
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
        subject.merge! other_user

        other_user.subscribed_channels.each do |c|
          subject.should be_subscribed(c)
        end
      end

      it "preserves channels the user was already subscribed to" do
        subject.merge! other_user

        previously_subscribed_channels.each do |c|
          subject.should be_subscribed(c)
        end
      end

      it "combines history, favorites, and queues of the two users" do
        subject.history_channel.should_receive(
          :merge!).with(other_user.history_channel)
          subject.favorite_channel.should_receive(
            :merge!).with(other_user.favorite_channel)
            subject.queue_channel.should_receive(
              :merge!).with(other_user.queue_channel)
              subject.merge! other_user

      end

      it "keeps the identity of the local (implicit) user" do
        primary_identity = subject.identity
        subject.merge! other_user
        subject.identity.should == primary_identity
      end

      describe "updating user information" do
        it "uses the other user's info when its missing" do
          subject.name = ""
          subject.email = ""
          other_user.name = "Joe"
          other_user.email = "joe@example.com"

          subject.merge! other_user
          subject.name.should == other_user.name
          subject.email.should == other_user.email
        end

        it "doesn't change info if the new user's is empty" do
          subject.name = "Joe"
          subject.email = "joe@example.com"

          subject.merge! other_user

          subject.name.should == "Joe"
          subject.email.should == "joe@example.com"
        end

        it "keeps local info if it is more current" do
          subject.updated_at = 1.day.ago
          other_user.updated_at = 10.days.ago

          subject.merge! other_user

          subject.name.should == "George"
          subject.email.should == "george@thejungle.com"
        end

        it "uses other info if it is more current" do
          subject.updated_at = 10.days.ago
          other_user.updated_at = 1.day.ago

          subject.merge! other_user

          subject.name.should == "Tarzan"
          subject.email.should == "tarzan@apes.gov"
        end
      end
    end
  end
end
