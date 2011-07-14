require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Channel do
  describe "#populate" do
    it "raises an exception unless overridden." do
      c = Factory :channel
      expect { c.populate }.to raise_error Aji::InterfaceMethodNotImplemented
    end
  end

  describe "#personalized_content_videos" do
    it "should return unviewed videos" do
      channel = create :channel
      viewed_video_ids = []

      # Create 10 videos for the channel, assume mock user has seen even ones.
      create_list(:youtube_video, 10).each_with_index do |v, i|
        channel.push v
        viewed_video_ids.push v.id if i % 2 == 0
      end

      user = mock("user")
      user.should_receive(:viewed_video_ids).at_least(1).and_return(
        viewed_video_ids)
      personalized_video_ids = channel.personalized_content_videos(
        :user => user).map(&:id)
      viewed_video_ids.each do | id |
        personalized_video_ids.should_not include id
      end
    end

    # TODO: This is Redis::Objects behavior and may not need testing... maybe.
    it "should return videos according to descending order on score" do
      channel = Factory :trending_channel
      10.times do |n|
        channel.push Factory(:video), rand(1000)
      end
      top_video  = channel.content_videos.first
      last_video = channel.content_videos.last
      top_video_relevance = channel.relevance_of top_video
      last_video_relevance= channel.relevance_of last_video
      top_video_relevance.should >= last_video_relevance

      viewed_video = channel.content_videos.sample
      user = Factory :user
      event = Factory :event, :event_type => :view, :user => user, :video => viewed_video
      personalized_videos = channel.personalized_content_videos :user=>user
      personalized_videos.should_not include viewed_video

      top_video_relevance = channel.relevance_of personalized_videos.first
      last_video_relevance= channel.relevance_of personalized_videos.last
      top_video_relevance.should >= last_video_relevance
    end

    it "should not return blacklisted videos" do
      channel = Factory :channel_with_videos
      user = Factory :user
      video = channel.content_videos.sample
      Aji::Video.blacklist_id video.id
      channel.personalized_content_videos(:user=>user,
        :limit=>channel.content_videos.count).should_not include video
    end

  end

  describe ".default_listing" do
    it "should return all channels marked as default" do
      n = 5
      channels = []
      n.times do |n|
        channels << Factory(:channel_with_videos, :default_listing=>false)
      end
      Aji::Channel.default_listing.should be_empty
      default_channel = channels[rand(n-1)]
      default_channel.default_listing = true
      default_channel.save
      Aji::Channel.default_listing.should include default_channel
    end
  end

end
