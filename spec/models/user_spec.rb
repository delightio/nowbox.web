require File.expand_path("../../spec_helper", __FILE__)

include Aji

describe Aji::User do
  subject do
    User.new do |u|
      u.stub(:id => 1)
      u.subscribed_list << 1
      u.name = "George"
      u.email = "george@thejungle.com"
      u.stub :history_channel => stub(:merge! => true, :push => true)
      u.stub :favorite_channel => stub(:merge! => true, :push => true)
      u.stub :queue_channel => stub(:merge! => true, :push => true)
      u.stub :recommended_channel => stub(:merge! => true, :push => true)
      u.stub :save => true
      u.stub :identity => identity
    end
  end

  let(:identity) { mock :identity, :hook => true }

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

  describe ".create_from" do
    it "creates a new object and copies from existing" do
      new_user = stub
      User.should_receive(:create).and_return(new_user)
      new_user.should_receive(:copy_from!).with(subject)

      User.create_from(subject).should == new_user
    end
  end

  describe "#initialize_settings" do
    subject { User.new }

    it "makes settings an empty hash if it is nil" do
      subject.send :initialize_settings

      subject.settings.should == {}
    end

    it "doesn't overwrite settings if it is already present" do
      subject.settings[:baked_goods] = "Yes Please!"
      subject.send :initialize_settings

      subject.settings.should have_key(:baked_goods)
      subject.settings[:baked_goods].should == "Yes Please!"
    end
  end

  describe "#create_user_channels" do
    it "creates user channels" do
      Channel::User.should_receive(:create).exactly(3).times
      subject.send :create_user_channels
    end
  end

  describe "#create_recommended_channel" do
    it "creates recommended channel" do
      Channel::Recommended.should_receive(:create).once
      subject.send :create_recommended_channel
    end
  end

  describe "#subscribe_featured_channels" do
    let(:featured_channels) do
      (1..3).map do |i|
        mock "channel", :id => i
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
    let(:video) { mock "video" }
    let(:channel) { mock "channel" }

    let(:event) do
      mock("event").tap do |e|
        e.stub :video => video
        e.stub :channel => channel
        e.stub :created_at => 3.minutes.ago
      end
    end

    describe "channel actions" do
      specify "subscribe subscribes to the channel" do
        event.stub :action => :subscribe
        subject.should_receive(:subscribe).with(channel)

        subject.process_event event
      end

      specify "unsubscribe removes the video from all subscriptions" do
        event.stub :action => :unsubscribe
        subject.should_receive(:unsubscribe_from_all).with(channel)

        subject.process_event event
      end
    end

    describe "video actions" do
      [ :view, :examine ].each do |action|
        specify "#{action} markes the video as watched by the user" do
          event.stub :action => action
          subject.should_receive(:watched_video).with(event.video,
            event.created_at)

          subject.process_event event
        end
      end


      specify "share favorites a video and marks it viewed" do
        event.stub :action => :share
        subject.should_not_receive(:favorite_video).with(video, event.created_at)
        subject.should_receive(:watched_video).with(video, event.created_at)

        subject.process_event event
      end

      specify "favorite favorites a video and marks it viewed" do
        event.stub :action => :favorite
        subject.should_receive(:favorite_video).with(video, event.created_at)
        subject.should_receive(:watched_video).with(video, event.created_at)

        subject.process_event event
      end


      specify "unfavorite unfavorites a video" do
        event.stub :action => :unfavorite
        subject.should_receive(:unfavorite_video).with(video)

        subject.process_event event
      end

      specify "dequeue dequeues the video" do
        event.stub :action => :dequeue
        subject.should_receive(:dequeue_video).with(video)

        subject.process_event event
      end

      specify "enqueue enqueues a video without marking it as watched" do
        event.stub :action => :enqueue
        subject.should_not_receive(:watched_video).with(video, event.created_at)
        subject.should_receive(:enqueue_video).with(video, event.created_at)

        subject.process_event event
      end
    end
  end

  describe "channel subscriptions" do
    let(:channel) { mock "channel", :id => 12 }

    describe "#unsubscribe_from_all" do
      before :each do
        subject.stub(:unsubscribe).with(channel).and_return(true)
        subject.stub(:unsubscribe_social).with(channel).and_return(true)
      end

      it "unsubscribes from regular channels and social subscription" do
        subject.should_receive(:unsubscribe).with(channel)
        subject.should_receive(:unsubscribe_social).with(channel)

        subject.unsubscribe_from_all channel
      end

      specify "returns true when the channel is not in either list" do
        subject.unsubscribe_from_all(channel).should be_true
      end

      specify "returns false when the channel is still subscribed" do
        subject.stub(:unsubscribe).with(channel).and_return(false)

        subject.unsubscribe_from_all(channel).should be_false
      end

      specify "returns false when the channel is still in social channels" do
        subject.stub(:unsubscribe_social).with(channel).and_return(false)
        subject.unsubscribe_from_all(channel).should be_false
      end
    end

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

    describe "video actions" do
      let(:time) { 3.seconds.ago }
      let(:history_channel) { mock "history channel", push: true, pop: true }
      let(:favorite_channel) { mock "favorite channel", push: true, pop: true }
      let(:queue_channel) { mock "queue channel", push: true, pop: true }
      let(:video) { mock "video" }
      let(:identity) { mock "identity", :hook => true }

      subject do
        User.new do |u|
          u.stub :id => 1
          u.stub :history_channel => history_channel
          u.stub :favorite_channel => favorite_channel
          u.stub :queue_channel => queue_channel
          u.stub :identity => identity
        end
      end

      describe "#watched_video" do

        it "adds the video to the user's history channel" do
          history_channel.should_receive(:push).with(video, time.to_i)

          subject.watched_video video, time
        end
      end

      describe "#favorite_video" do
        it "adds the video to the user's favorites channel" do
          favorite_channel.should_receive(:push).with(video, time.to_i)

          subject.favorite_video video, time
        end

        it "triggers the identity's :favorite hook" do
          identity.should_receive(:hook).with(:favorite, video)

          subject.favorite_video video, time
        end
      end

      describe "#unfavorite_video" do
        it "removes the video from the user's favorites channel" do
          favorite_channel.should_receive(:pop).with(video)

          subject.unfavorite_video video
        end

        it "triggers the identity's :unfavorite hook" do
          identity.should_receive(:hook).with(:unfavorite, video)

          subject.unfavorite_video video
        end
      end

      describe "#enqueue_video" do
        it "adds the video to the user's queue channel" do
          queue_channel.should_receive(:push).with(video, time.to_i)

          subject.enqueue_video video, time
        end

        it "triggers the identity's :enqueue hook" do
          identity.should_receive(:hook).with(:enqueue, video)

          subject.enqueue_video video, time
        end
      end

      describe "#dequeue_video" do
        it "removes the video from the user's queueu channel" do
          queue_channel.should_receive(:pop).with(video)

          subject.dequeue_video video
        end

        it "triggers the identity's :dequeue hook" do
          identity.should_receive(:hook).with(:dequeue, video)

          subject.dequeue_video video
        end
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
      let(:identity) { mock "identity", :hook => true }
      before { subject.stub :identity => identity }

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

        it "triggers the identity's :subscribe hook" do
          identity.should_receive(:hook).with(:subscribe, channel)

          subject.subscribe channel
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
      let(:identity) { mock "identity", :hook => true }
      before { subject.stub :identity => identity }

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

      it "triggers the identity's :unsubscribe hook" do
        identity.should_receive(:hook).with(:unsubscribe, channel)

        subject.unsubscribe channel
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

  describe "temporary account stuff" do
    describe "#twitter_account" do
      subject { User.new { |u| u.stub :social_channels => [twitter_channel] } }
      let(:twitter_channel) do
        mock "channel", :owner => mock("tw account"),
          :class => Channel::TwitterStream
      end

      specify "the account associated with the users twitter channel" do
        subject.twitter_account.should == twitter_channel.owner
      end

      specify "nil when no twitter channel in social subscriptions" do
        subject.stub :social_channels => []

        subject.twitter_account.should be_nil
      end
    end

    describe "#facebook_account" do
      subject { User.new { |u| u.stub :social_channels => [facebook_channel] } }
      let(:facebook_channel) do
        mock "channel", :owner => mock("fb account"),
          :class => Channel::FacebookStream
      end

      specify "the account associated with the users facebook channel" do
        subject.facebook_account.should == facebook_channel.owner
      end

      specify "nil when no facebook channel in social subscriptions" do
        subject.stub :social_channels => []

        subject.facebook_account.should be_nil
      end
    end

    describe "#enable_twitter_post" do
      subject { User.new }
      it "sets :post_to_twitter to true" do
        subject.enable_twitter_post.should be_true

        subject.reload.settings[:post_to_twitter].should be_true
      end
    end

    describe "#enable_facebook_post" do
      subject { User.new }
      it "sets :post_to_facebook to true" do
        subject.enable_facebook_post.should be_true

        subject.reload.settings[:post_to_facebook].should be_true
      end
    end

    describe "#autopost_accounts" do
      let(:twitter_account) { mock "twitter account" }
      let(:facebook_account) { mock "facebook account" }
      let(:settings) { { :post_to_twitter => true } }

      subject do
        User.new do |u|
          u.stub :twitter_account => twitter_account
          u.stub :facebook_account => facebook_account
          u.stub :settings => settings
        end
      end

      it "returns a user's social accounts which are set to autopost" do
        subject.autopost_accounts.should == [twitter_account]
      end
    end
  end

  describe "#user_channels" do
    it "returns all user channels" do
      subject.user_channels.should include subject.history_channel
      subject.user_channels.should include subject.queue_channel
      subject.user_channels.should include subject.favorite_channel
    end
  end

  describe "#display_channels" do
    let(:displayable_user_channels) { [mock("fav channel"), mock("queue channel")] }
    let(:subscribed_channels) { [mock("hilarious channel")] }
    let(:social_channels) { [mock("fb channel"), mock("twitter channel")] }
    let(:recommended_channel) { mock "recommended" }

    it "returns an array of of all displayable channels" do
      subject.stub(:displayable_user_channels).and_return(displayable_user_channels)
      subject.stub(:subscribed_channels).and_return(subscribed_channels)
      subject.stub(:social_channels).and_return(social_channels)
      subject.stub :recommended_channel => recommended_channel
      subject.display_channels.should == displayable_user_channels +
        social_channels + [recommended_channel] + subscribed_channels
    end
  end

  describe "#serializable_hash" do
    subject do
      User.new do |u|
        u.stub :id => 111
        u.stub :name => "Jim"
        u.stub :email => "jim@james.com"
        u.stub :queue_channel_id => 1
        u.stub :favorite_channel_id => 2
        u.stub :history_channel_id => 3
        u.stub :recommended_channel_id => 4
        u.stub :twitter_channel_id => nil
        u.stub :facebook_channel_id => 5
        u.stub :subscribed_channel_ids => [6,7,8,9,10]
        u.stub :identity => stub(:account_info => [{
          'provider' => 'youtube', 'uid' => 'nuclearsandwich',
          'username' => 'nuclearsandwich', 'synchronized_at' => Time.new(2011)
        }])
      end
    end

    it "returns a hash of users attributes" do
      subject.serializable_hash.should == {
        'id' => 111,
        'name' => "Jim",
        'email' => "jim@james.com",
        'queue_channel_id' => 1,
        'favorite_channel_id' => 2,
        'history_channel_id' => 3,
        'recommended_channel_id' => 4,
        'twitter_channel_id' => nil,
        'facebook_channel_id' => 5,
        'subscribed_channel_ids' => [6,7,8,9,10],
        'accounts' => [{ 'provider' => 'youtube', 'uid' => 'nuclearsandwich',
          'username' => 'nuclearsandwich', 'synchronized_at' => Time.new(2011)
        }]
      }
    end
  end

  describe "#subscribed_channel_ids" do
    let(:subscribed_ids) { [1, 50, 27, 9] }
    let(:subscribed_list) { stub :values => subscribed_ids.map(&:to_s) }
    subject { User.new { |u| u.stub :subscribed_list => subscribed_list } }

    it "returns a list of ids from the subscribed list" do
      subject.subscribed_channel_ids.should == subscribed_ids
    end

    it "doesn't include ids that with missing channels"
  end

  describe "#twitter_channel_id" do
    let(:tw_channel) { stub :id => 9, :class => Aji::Channel::TwitterStream }

    it "returns the id of the twitter channel if one is present" do
      subject.stub :social_channels => [stub, tw_channel]

      subject.twitter_channel_id.should == tw_channel.id
    end

    it "returns nil if no facebook channel is present" do
      subject.stub :social_channels => [stub, stub]
      subject.twitter_channel_id.should be_nil
    end
  end


  describe "#facebook_channel_id" do
    let(:fb_channel) { stub :id => 8, :class => Aji::Channel::FacebookStream }

    it "returns the id of the facebook channel if one is present" do
      subject.stub :social_channels => [stub, fb_channel]

      subject.facebook_channel_id.should == fb_channel.id
    end

    it "returns nil if no facebook channel is present" do
      subject.stub :social_channels => [stub, stub]
      subject.facebook_channel_id.should be_nil
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

  describe "#copy_from!" do
    let(:social1) { mock }
    let(:other_user) { stub :social_channels => [ social1 ] }

    it "merges and copies social channels" do
      subject.should_receive :merge!
      subject.should_receive(:subscribe_social).with(social1)
      subject.copy_from! other_user
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

    it "combines recommended, history, favorites, and queues of the two users" do
      subject.history_channel.should_receive(
        :merge!).with(other_user.history_channel)
      subject.favorite_channel.should_receive(
        :merge!).with(other_user.favorite_channel)
      subject.queue_channel.should_receive(
        :merge!).with(other_user.queue_channel)
      subject.recommended_channel.should_receive(
        :merge!).with(other_user.recommended_channel)


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

  describe "#favorite_videos" do
    it "returns videos in the user's favorites channel" do
      subject.favorite_channel.should_receive(:content_videos)

      subject.favorite_videos
    end
  end

  describe "#queued_videos" do
    it "returns videos in the user's favorites channel" do
      subject.queue_channel.should_receive(:content_videos)

      subject.queued_videos
    end
  end

  describe "#youtube_channels" do
    subject do
      User.new.tap{ |u| u.stub :subscribed_channels => subscribed_channels }
    end

    let(:youtube_channels) do
      [stub(:youtube_channel? => true), stub(:youtube_channel? => true)]
    end

    let(:other_channels) do
      [stub(:youtube_channel? => false), stub(:youtube_channel? => false)]
    end

    let(:subscribed_channels) { youtube_channels + other_channels }

    it "returns all subscribed channels with a single youtube author" do
      subject.youtube_channels.should == youtube_channels
    end
  end

  describe "#without_hooks!" do
    let(:video) { stub.as_null_object }

    it "prevents hooks from being sent to the identity" do
      identity.should_not_receive(:hook)

      subject.without_hooks! do
        subject.favorite_video video, Time.now
      end
    end

    it "only lasts the duration of the given block" do
      identity.should_receive(:hook).with(:favorite, video)

      subject.without_hooks! {}
      subject.favorite_video video, Time.now
    end
  end
end

