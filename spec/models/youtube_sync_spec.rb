require './models/youtube_sync'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/time/calculations'
require 'active_support/core_ext/time/acts_like'
require 'active_support/duration'
require 'pry'

unless Aji.respond_to? :conf
  Resque = Module.new
  Aji::Queues = Module.new
  Aji::Queues::SynchronizeWithYoutube = Class.new
end

describe Aji::YoutubeSync, :unit do
  before do
    Resque.stub :enqueue_in

    def user.suppress_hooks!
      yield
    end
  end

  subject { Aji::YoutubeSync.new account }

  let(:account) do
    mock "account", :api => api, :id => 11, :user => user, :save => true,
      :synchronized_at= => true, :synchronized_at => 1.hour.ago
  end

  let(:user) do
    mock "user", :subscribe => true, :unsubscribe => true,
      :youtube_channels => remotely_unsubscribed_channels + other_channels,
      :queued_videos => queued_videos, :favorite_videos => favorite_videos,
      :enqueue_video => true, :dequeue_video => true, :favorite_video => true,
      :unfavorite_video => true
  end

  let(:api) do
    mock("youtube api").tap do |a|
      a.stub :subscriptions => youtube_subscriptions
      a.stub :watch_later_videos => youtube_watch_later_videos
      a.stub :favorite_videos => youtube_favorite_videos
      a.stub :add_to_favorites => true
      a.stub :add_to_watch_later => true
      a.stub :subscribe_to => true
    end
  end

  let(:youtube_subscriptions) { other_channels }
  let(:youtube_watch_later_videos) do
    other_queued_videos.select{ |v| v.source == :youtubei }
  end

  let(:youtube_favorite_videos) do
    other_favorite_videos.select{ |v| v.source == :youtube }
  end

  let(:remotely_unsubscribed_channels) do
    [stub(:youtube_id => "channel1"), stub(:youtube_id => "channel2"),
     stub(:youtube_id => "channel3")]
  end

  let(:remotely_unfavorited_videos) do
    [stub(:external_id => "video1", :source => :youtube)]
  end

  let(:remotely_watched_videos) do
    [stub(:external_id => "video2", :source => :youtube)]
  end

  let(:other_channels) do
    [ stub(:background_refresh_content => []),
      stub(:background_refresh_content => []) ]
  end

  let(:other_queued_videos) do
    [stub(:external_id => "video3", :source => :youtube), stub(:source => :vimeo)]
  end

  let(:other_favorite_videos) do
    [stub(:external_id => "video4", :source => :youtube), stub(:source => :vimeo)]
  end

  let(:queued_videos) { remotely_watched_videos + other_queued_videos }
  let(:favorite_videos) { remotely_unfavorited_videos + other_favorite_videos }

  describe "#synchronize!" do
    it "suppresses atomic user hooks when running" do
      user.should_receive(:suppress_hooks!)

      subject.synchronize!
    end

    it "exits without enqueueing resync if account or user is invalid" do
      subject.stub :account => nil
      subject.should_not_receive(:enqueue_resync)

      subject.synchronize!

      subject.stub :user => nil
      subject.should_not_receive(:enqueue_resync)

      subject.synchronize!
    end

    it "runs subscribed channel sync" do
      subject.should_receive(:sync_subscribed_channels)

      subject.synchronize!
    end

    it "runs watch later channel sync" do
      subject.should_receive(:sync_watch_later)

      subject.synchronize!
    end

    it "runs favorites channel sync" do
      subject.should_receive(:sync_favorites)

      subject.synchronize!
    end

    it "enqueues the next synchronization" do
      subject.should_receive(:enqueue_resync)

      subject.synchronize!
    end

    it "doesn't enqueue a resync when doing so is disabled" do
      subject.should_not_receive(:enqueue_resync)

      subject.synchronize! :disable_resync
    end

    it "updates the time at which the account was synchronized" do
      account.should_receive(:synchronized_at=).with(anything)
      account.should_receive(:save)

      subject.synchronize!
    end
  end

  describe "#sync_subscribed_channels" do
    it "subscribes the user to all account's youtube subscription" do
      youtube_subscriptions.each do |c|
        user.should_receive(:subscribe).with(c)

        subject.sync_subscribed_channels
      end
    end

    it "refreshes the incoming channel content in the background" do
      youtube_subscriptions.each do |c|
        c.should_receive(:background_refresh_content)
      end

      subject.sync_subscribed_channels
    end

    it "unsubscribes the local user from removed youtube subscriptions" do
      pending "removed feature until we unsubscribe using activity feed"
      remotely_unsubscribed_channels.each do |c|
        user.should_receive(:unsubscribe).with(c)
      end

      subject.sync_subscribed_channels
    end

    it "does not unsubscribe any other channels" do
      other_channels.each do |c|
        user.should_not_receive(:unsubscribe).with(c)
      end

      subject.sync_subscribed_channels
    end
  end

  describe "#sync_watch_later" do
    it "adds youtube watch later to the user's queue_channel" do
      youtube_watch_later_videos.each do |v|
        user.should_receive(:enqueue_video).with(v, anything)
      end

      subject.sync_watch_later
    end

    it "removes remotely watched videos" do
      pending "removed feature until we unsubscribe using activity feed"
      remotely_watched_videos.each do |v|
        user.should_receive(:dequeue_video).with(v)
      end

      subject.sync_watch_later
    end

    it "does not remove other queued videos" do
      other_queued_videos.each do |v|
        user.should_not_receive(:dequeue_video).with(v)
      end

      subject.sync_watch_later
    end
  end

  describe "#sync_favorites" do
    it "favorites videos from youtube on the user's favorites channel" do
      youtube_favorite_videos.should == subject.account.api.favorite_videos
      youtube_favorite_videos.each do |v|
        user.should_receive(:favorite_video).with(v, anything)
      end

      subject.sync_favorites
    end

    it "removes unfavorited videos" do
      pending "removed feature until we unsubscribe using activity feed"
      remotely_unfavorited_videos.each do |v|
        user.should_receive(:unfavorite_video).with(v)
      end

      subject.sync_favorites
    end

    it "does not remove other favorite videos" do
      other_favorite_videos.each do |v|
        user.should_not_receive(:unfavorite).with(v)
      end

      subject.sync_watch_later
    end
  end

  describe "#enqueue_resync" do
    it "sets up a delayed resque job to run again in 24 hours" do
      Resque.should_receive(:enqueue_in).with(1.day,
        Aji::Queues::SynchronizeWithYoutube, account.id)

      subject.enqueue_resync
    end

    it "doesn't reenqueue when synchronized less than 30 minutes ago" do
      Resque.should_not_receive(:enqueue_in)
      account.stub :synchronized_at => 2.minutes.ago

      subject.enqueue_resync
    end
  end

  describe "#youtube_subscriptions" do
    it "returns cached subscriptions from the api" do
      api.should_receive(:subscriptions).exactly(1)

      subject.youtube_subscriptions
      subject.youtube_subscriptions
      subject.youtube_subscriptions
    end
  end

  describe "#youtube_watch_later_videos" do
    it "returns cached videos in the api's watch later playlist" do
      api.should_receive(:watch_later_videos).exactly(1)

      subject.youtube_watch_later_videos
      subject.youtube_watch_later_videos
      subject.youtube_watch_later_videos
    end
  end

  describe "#youtube_favorite_videos" do
    it "returns cached favorite videos from the youtube api" do
      api.should_receive(:favorite_videos).exactly(1)

      subject.youtube_favorite_videos
      subject.youtube_favorite_videos
      subject.youtube_favorite_videos
    end
  end

  describe "#push_and_synchronize!" do
    it "pushes videos and channels to youtube before sync" do
      subject.should_receive(:push_subscribed_channels)
      subject.should_receive(:push_favorite_videos)
      subject.should_receive(:push_watch_later_videos)

      subject.should_receive(:synchronize!)

      subject.push_and_synchronize!
    end
  end

  describe "#push_subscribed_channels" do
    it "subscribes to all locally subscribed youtube channels on youtube" do
      remotely_unsubscribed_channels.each do |channel|
        api.should_receive(:subscribe_to).with(channel.youtube_id)
      end

      subject.push_subscribed_channels
    end

    it "clears the youtube subscriptions cache" do
      subject.push_subscribed_channels
      subject.instance_variable_get(:@youtube_subscriptions).should be_nil
    end
  end

  describe "#push_favorite_videos" do
    it "adds all locally favorited youtube videos to youtube favorites" do
      remotely_unfavorited_videos.each do |video|
        api.should_receive(:add_to_favorites).with(video.external_id)
      end

      subject.push_favorite_videos
    end

    it "clears the youtube favorites cache" do
      subject.push_favorite_videos
      subject.instance_variable_get(:@youtube_favorite_videos).should be_nil
    end
  end

  describe "#push_watch_later_videos" do
    it "adds all locally enqueued youtube videos to youtube watch later" do
      remotely_watched_videos.each do |video|
        api.should_receive(:add_to_watch_later).with(video.external_id)
      end

      subject.push_watch_later_videos
    end

    it "clears the youtube watch later cache" do
      subject.push_watch_later_videos
      subject.instance_variable_get(:@youtube_watch_later_videos).should be_nil
    end
  end

  describe "#background_synchronize!" do
    it "sets up a resque job to run synchronization" do
      Resque.should_receive(:enqueue).with(
        Aji::Queues::SynchronizeWithYoutube, account.id, false)

      subject.background_synchronize!
    end

    it "passes it's argument down to resque" do
      Resque.should_receive(:enqueue).with(
        Aji::Queues::SynchronizeWithYoutube, account.id, :disable_resync)

      subject.background_synchronize! :disable_resync
    end
  end

  describe "#background_push_and_synchronize!" do
    it "sets up a resque job to run push and synchronization" do
      Resque.should_receive(:enqueue).with(
        Aji::Queues::SynchronizeWithYoutube, account.id, false, :push_first)

      subject.background_push_and_synchronize!
    end

    it "passes it's argument down to resque" do
      Resque.should_receive(:enqueue).with(
        Aji::Queues::SynchronizeWithYoutube, account.id, :disable_resync,
        :push_first)

      subject.background_push_and_synchronize! :disable_resync
    end
  end
end

