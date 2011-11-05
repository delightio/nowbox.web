require './models/youtube_sync'
require 'active_support/all'

describe Aji::YoutubeSync do
  before do
    Resque = stub
    Aji::Queues = Module.new
    Aji::Queues::YoutubeSync = stub
  end

  subject { Aji::YoutubeSync.new account }
  let(:account) { mock "account", :api => api, :id => 11, :user => user }
  let(:user) { stub }

  let(:api) do
    mock("youtube api").tap do |a|
      a.stub :subscribed_channels => youtube_subscribed_channels
      a.stub :watch_later_videos => youtube_watch_later_videos
      a.stub :favorite_videos => youtube_favorite_videos
    end
  end

  let(:youtube_subscribed_channels) do
    [ stub, stub, stub ]
  end

  let(:youtube_watch_later_videos) do
    [ stub, stub ]
  end

  let(:youtube_favorite_videos) do
    [ stub, stub, stub, stub ]
  end

  describe "#synchronize!" do
    it "runs subscribed channel sync" do
      subject.should_receive(:sync_subscribed_channels)

      subject.synchronize!
    end

    it "runs watch later channel sync" do
      subject.should_receive(:sync_watched_later)

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
  end

  describe "#enqueue_resync" do
    it "sets up a delayed resque job to run again in 24 hours" do
      Resque.should_receive(:enqueue_at).with(1.day, Aji::Queues::YoutubeSync,
        account.id)

      subject.enqueue_resync
    end
  end
  xit "subscribes the user to all account's youtube subscription" do
    youtube_subscribed_channels.each do |c|
      user.should_receive(:subscribe).with(c)
    end
  end


  xit "adds youtube watch later to the user's queue_channel" do
    youtube_watch_later_videos.each do |v|
      user.should_receive(:enqueue_video).with(v)
    end
  end



  xit "favorites videos from youtube on the user's favorites channel" do
    youtube_favorite_videos.each do |v|
      user.should_receive(:favorite_video).with(v)
    end
  end
end


# TODO: These will happen atomically and should be tested elsewhere.
#  it "favorites videos from the user's favorites channel on youtube"
#  it "subscribes the account to all the user's youtube channels"
#  it "adds videos from the user's queue channel to watch later"
#  it "unsubscribes from youtube channels when they're unsubscribed locally"
