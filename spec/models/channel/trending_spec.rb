require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Channel::Trending do
  subject { Aji::Channel.trending }
  
  describe "singleton" do
    it "creates a new singleton when none exists" do
      expect { Aji::Channel::Trending.singleton }.
        to change(Aji::Channel::Trending, :count).from(0).to(1)
    end

    it "doesn't create if one already exists" do
      Aji::Channel::Trending.singleton
      expect { Aji::Channel::Trending.singleton }.
        not_to change(Aji::Channel::Trending, :count)
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

  describe "#refresh_content" do
    it "marks self populated" do
      subject.refresh_content
      subject.should be_populated
    end

    context "after #refresh_content" do
      before(:each) do
        real_youtube_video_ids = %w[ l4qv4Ca1h94 Wx7c7nHXqKg BoTvCgJtcJU ]
        real_youtube_video_ids.each{ |yt_id|
          subject.push_recent( Factory :video_with_mentions,
                                       :source => :youtube,
                                       :external_id => yt_id) }

         old_video = Factory :video_with_mentions
         old_video.mentions.each {|m| m.published_at = 1.years.ago; m.save }
         subject.push_recent old_video

        Aji.stub(:conf).and_return(
          { 'MAX_RECENT_VIDEO_IDS_IN_TRENDING'=>real_youtube_video_ids.count*2,
            'MAX_VIDEOS_IN_TRENDING' => real_youtube_video_ids.count})

        subject.refresh_content
      end

      specify "all content_videos are populated" do
        subject.content_videos.each do |video|
          video.should be_populated
        end
      end

      specify "not all recent_videos are populated" do
        subject.recent_video_ids.select{ |vid|
          !Aji::Video.find(vid).populated? }.
            should have(1).video
      end
    end

    it "returns videos in descending order of relevance" do
      10.times.each { |n| subject.push_recent(Factory :populated_video_with_mentions) }
      subject.refresh_content
      trending_videos = subject.content_videos
      subject.relevance_of(trending_videos.first).should >= subject.relevance_of(trending_videos.last)
    end

    it "does not include blacklisted videos" do
      video = Factory :populated_video_with_mentions
      subject.push_recent video
      video.blacklist

      subject.refresh_content
      subject.content_videos.count.should == 0
    end
  end
end
