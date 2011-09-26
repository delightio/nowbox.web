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

  describe "#refresh_content" do
    it "marks self populated" do
      subject.refresh_content
      subject.should be_populated
    end

    context "when an old video with high relevance is not in recent videos anymore" do
      before(:each) do
        @video1 = mock("video", :id=>1)
        @video1.should_receive(:populate)
        @video1.stub(:populated?).and_return(true)

        @video2 = mock("video", :id=>2)
        @video2.should_receive(:populate)
        @video2.stub(:populated?).and_return(true)

        [@video1, @video2].each do | v |
          Aji::Video.should_receive(:find_by_id).with(v.id).and_return(v)
        end
      end

      it "should not be in content videos" do
        subject.stub(:sorted_recent_videos).with(an_instance_of(Fixnum)).
          and_return([{:video=>@video1, :relevance=>1000}])
        subject.should_receive(:create_channels_from_top_authors).
          with([@video1])
        subject.refresh_content
        subject.stub(:sorted_recent_videos).with(an_instance_of(Fixnum)).
          and_return([{:video=>@video2, :relevance=>2000}])
        subject.should_receive(:create_channels_from_top_authors).
          with([@video2])
        subject.refresh_content true
        subject.content_video_ids.should_not include @video1.id
      end
    end

    context "after #refresh_content" do
      before(:each) do
        real_youtube_video_ids = %w[ l4qv4Ca1h94 Wx7c7nHXqKg BoTvCgJtcJU ]
        real_youtube_video_ids.each{ |yt_id|
          subject.push_recent( Factory :video_with_mentions,
                                       :source => :youtube,
                                       :external_id => yt_id) }
      
        old_video = Factory :video_with_mentions
        old_video.mentions.each { |m| m.update_attribute :published_at,
          1.years.ago }
        subject.push_recent old_video
      
        Aji.stub(:conf).and_return(
          { 'MAX_RECENT_VIDEO_IDS_IN_TRENDING'=>real_youtube_video_ids.count*2,
            'MAX_VIDEOS_IN_TRENDING' => real_youtube_video_ids.count})
      end

      specify "all content_videos are populated" do
        subject.refresh_content
        subject.content_videos.each do |video|
          video.should be_populated, "expected video[#{video.id}].populated? " +
            "to be populated but it was not"
        end
      end

      specify "not all recent_videos are populated" do
        subject.refresh_content
        subject.recent_videos.select{ |video| !video.populated? }.
          should have(1).video
      end

      it "respects MAX_VIDEOS_IN_TRENDING" do
        pending "Brittle do to chance that video will fail to populate."
        subject.refresh_content
        subject.content_videos.should have(
          Aji.conf['MAX_VIDEOS_IN_TRENDING']).videos

        video = Factory :video_with_mentions
        video.mentions.each {|m| m.update_attribute :published_at, Time.now }
        subject.push_recent video
        subject.refresh_content
        subject.content_videos.should have(
          Aji.conf['MAX_VIDEOS_IN_TRENDING']).videos
        subject.content_videos.first.should == video
      end

      it "creates channels from author of top videos" do
        pending "Why isn't this working?"
        Aji::Account.any_instance.should_receive(:to_channel).
          exactly(3).times.
          and_return(Factory :channel)
        Resque.should_receive(:enqueue).with(
          Aji::Queues::RefreshChannel, an_instance_of(Fixnum)).
          exactly(3).times
        subject.refresh_content
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

    it "only continues if we have any recent videos. Otherwise, keep existing content" do
      expect { subject.refresh_content }.
        to_not change { subject.content_videos }
    end

  end

  # describe "#sorted_recent_videos" do
  #   before :each do
  #     @recent_videos = []
  #     3.times.do |n|
  #       v = mock("video")
  #       v.stub(:blacklisted?).and_return(false)
  #       v.stub(:relevance).with(instance_of(Fixnum)).and_return(n*1000)
  #     end
  #   end
  # 
  #   it "sorts all recent videos by relevance" do
  #     subject.stub(:recent_videos).and_return(@recent_videos)
  #     sorted = subject.sorted_recent_videos
  #     sorted.should have(3).videos
  #     sorted.should == [@recent_videos[2], @recent_videos[1], @recent_videos[0]]
  #   end
  # 
  #   it "ignores blacklisted videos" do
  #     blacklisted = mock("video")
  #     blacklisted.stub(:blacklisted?).and_return(true)
  #     subject.stub(:recent_videos).and_return(@recent_videos<<blacklisted)
  #     sorted = subject.sorted_recent_videos
  #     sorted.should have(3).videos
  #     sorted.should_not include blacklisted
  #   end
  # end
end
