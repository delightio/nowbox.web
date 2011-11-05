require File.expand_path("../../spec_helper", __FILE__)

include Aji

describe YoutubeSync do
  let(:user) { mock "user", :api => api }
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

  it "subscribes the user to all account's youtube subscription" do
    youtube_subscribed_channels.each do |c|
      user.should_receive(:subscribe).with(c)
    end
  end


  it "adds youtube watch later to the user's queue_channel" do
    youtube_watch_later_videos.each do |v|
      user.should_receive(:enqueue_video).with(v)
    end
  end



  it "favorites videos from youtube on the user's favorites channel" do
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
