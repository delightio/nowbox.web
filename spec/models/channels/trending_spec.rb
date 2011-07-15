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
    
    it "should populate videos in trending channel" do
      trending = Factory :trending_channel
      
      real_youtube_video_ids = %w[ l4qv4Ca1h94 Wx7c7nHXqKg BoTvCgJtcJU ]
      real_youtube_video_ids.each{ |yt_id| 
        trending.push_recent( Factory :video_with_mentions,
                                        :source => :youtube,
                                        :external_id => yt_id) }
      
      # Create an video with very old mentions
      old_video = Factory :video_with_mentions
      old_video.mentions.each {|m| m.published_at = 1.years.ago; m.save }
      trending.push_recent old_video
      
      Aji.stub(:conf).and_return(
        { 'MAX_RECENT_VIDEO_IDS_IN_TRENDING'=>real_youtube_video_ids.count*2,
          'MAX_VIDEOS_IN_TRENDING' => real_youtube_video_ids.count})
      
      trending.populate
      
      # All videos in content_videos should be populated
      trending.content_videos.each { |v| v.should be_populated }
      
      # Not all recent videos are populated
      trending.recent_video_ids.should include old_video.id
      old_video.should_not be_populated
    end
    
    it "should return videos in descending order of relevance" do
      trending = Factory :trending_channel
      10.times.each { |n| trending.push_recent(Factory :populated_video_with_mentions) }
      trending.populate
      trending_videos = trending.content_videos
      trending.relevance_of(trending_videos.first).should >= trending.relevance_of(trending_videos.last)
    end
    
    it "should not include blacklisted videos" do
      trending = Factory :trending_channel
      video = Factory :populated_video_with_mentions
      trending.push_recent video
      Aji::Video.blacklist_id video.id
      
      trending.populate
      trending.content_videos.count.should == 0
    end
  end
end