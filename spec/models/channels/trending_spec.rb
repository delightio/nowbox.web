require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Channels::Trending do
  describe "push_recent" do
    it "should only keep given number of mentioned videos" do
      trending = Factory :trending_channel
      n = 2
      Aji.stub(:conf).and_return({'MAX_RECENT_VIDEO_IDS_IN_TRENDING'=>n})
      (n*2).times {|k| trending.push_recent(Factory :video)}
      trending.recent_video_ids.count.should == n
    end
  end

  describe "#populate" do
    it "should populate videos (if not already) and only keep a max number of videos in content" do
      real_youtube_video_ids = %w[l4qv4Ca1h94 716O3L-Xnfs Wx7c7nHXqKg Zzi-5CO4-G0 xs-rgXUu448 BoTvCgJtcJU ]
      max_recent_videos = real_youtube_video_ids.count
      max_videos_in_trending = max_recent_videos / 2
      Aji.stub(:conf).and_return(
        { 'MAX_RECENT_VIDEO_IDS_IN_TRENDING'=>max_recent_videos,
          'MAX_VIDEOS_IN_TRENDING' => max_videos_in_trending})
      
      trending = Factory :trending_channel
      tests_populated_videos = []
      # random insertion time
      max_recent_videos.times{ |k| trending.push_recent(
        (Factory :video, :source => :youtube, :external_id => real_youtube_video_ids[k]),
        rand(1000)) } 
      max_recent_videos.times{ |k| trending.push_recent((Factory :populated_video), rand(1000)) }
      
      trending.content_videos.should be_empty
      trending.recent_video_ids.count.should == max_recent_videos
      
      trending.populate
      trending_videos = trending.content_videos
      trending_videos.count.should == max_videos_in_trending
      trending_videos.each { |v| v.is_populated?.should be_true }
      trending.relevance_of(trending_videos.first).should >= trending.relevance_of(trending_videos.last)
    end
  end
end