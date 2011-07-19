require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Channels::Trending do
  subject { Aji::Channel.trending }
  
  describe "singleton" do
    it "creates a new singleton when none exists" do
      expect { Aji::Channels::Trending.singleton }.
        to change(Aji::Channels::Trending, :count).from(0).to(1)
    end

    it "doesn't create if one already exists" do
      Aji::Channels::Trending.singleton
      expect { Aji::Channels::Trending.singleton }.
        not_to change(Aji::Channels::Trending, :count)
    end
  end

  describe "#push_recent" do
    it "should only keep given number of mentioned videos" do
      n = 2
      Aji.stub(:conf).and_return({'MAX_RECENT_VIDEO_IDS_IN_TRENDING'=>n})
      (n*2).times {|k| subject.push_recent(Factory :video)}
      subject.recent_video_ids.count.should == n
    end
  end

  describe "#populate" do
    it "should be populated afterward" do
      subject.populate
      subject.should be_populated
    end
    
    it "should populate videos in trending channel" do
      real_youtube_video_ids = %w[ l4qv4Ca1h94 Wx7c7nHXqKg BoTvCgJtcJU ]
      real_youtube_video_ids.each{ |yt_id|
        subject.push_recent( Factory :video_with_mentions,
                                     :source => :youtube,
                                     :external_id => yt_id) }

      # Create an video with very old mentions
      old_video = Factory :video_with_mentions
      old_video.mentions.each {|m| m.published_at = 1.years.ago; m.save }
      subject.push_recent old_video

      Aji.stub(:conf).and_return(
        { 'MAX_RECENT_VIDEO_IDS_IN_TRENDING'=>real_youtube_video_ids.count*2,
          'MAX_VIDEOS_IN_TRENDING' => real_youtube_video_ids.count})

      subject.populate

      # All videos in content_videos should be populated
      subject.content_videos.each { |v| v.should be_populated }

      # Not all recent videos are populated
      subject.recent_video_ids.should include old_video.id
      old_video.should_not be_populated
    end

    it "should return videos in descending order of relevance" do
      10.times.each { |n| subject.push_recent(Factory :populated_video_with_mentions) }
      subject.populate
      trending_videos = subject.content_videos
      subject.relevance_of(trending_videos.first).should >= subject.relevance_of(trending_videos.last)
    end

    it "should not include blacklisted videos" do
      video = Factory :populated_video_with_mentions
      subject.push_recent video
      video.blacklist

      subject.populate
      subject.content_videos.count.should == 0
    end
  end
end
