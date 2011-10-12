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
    before :each do
      @videos = []
      5.times do |n|
        v = mock("video", :id => n, :blacklisted? => false, :author => mock)
        v.stub(:populate).and_yield(v)
        Aji::Video.stub(:find_by_id).with(v.id).and_return(v)
        subject.stub(:recent_relevance_of).with(v).and_return(n*1000)

        @videos << v
        subject.push_recent v
      end

      subject.stub(:adjust_relevance_in_all_recent_videos)
      subject.stub(:create_channels_from_top_authors)
    end

    it "always marks self populated" do
      subject.refresh_content
      subject.should be_populated
    end

    it "adjusts relevances for all recent videos and remove videos with negative relevance" do
      subject.should_receive(:adjust_relevance_in_all_recent_videos).
        with(an_instance_of(Fixnum), true)
      subject.refresh_content
    end

    it "pushes trending videos into content_video with relevance from recent set" do
      @videos.each do |v|
        subject.should_receive(:push).
          with(v, subject.recent_relevance_of(v))
      end
      subject.refresh_content
    end

    it "populates all videos in content_videos" do
      @videos.each {|v| v.should_receive(:populate) }
      subject.refresh_content
    end

    it "does not include blacklisted videos" do
      blacklisted = @videos.sample
      blacklisted.stub(:blacklisted?).and_return true
      blacklisted.should_not_receive(:populate)

      subject.refresh_content
      subject.content_videos.should_not include blacklisted
    end

    it "creates channels from author of top videos" do
      subject.should_receive(:create_channels_from_top_authors)
      subject.refresh_content
    end

    let(:limit) { @videos.count/2 }
    it "respects MAX_VIDEOS_IN_TRENDING" do
      Aji.stub(:conf).and_return('MAX_VIDEOS_IN_TRENDING'=>limit)
      subject.refresh_content
      subject.content_videos.should have(limit).videos
    end
  end

  describe "#create_channels_from_top_authors" do
    let(:channel) { mock("channel", :id=>1)}
    let(:authors) { [mock("author", :username=>"John", :to_channel=>channel)] }
    it "background refresh given authors" do
      channel.should_receive(:background_refresh_content)
      subject.send(:create_channels_from_top_authors, authors)
    end
  end

  describe "#promote_video" do
    let(:video) { mock "video", :id=>1 }
    let(:trigger) { mock "trigger", :significance => 1000 }
    it "increment the relevance (in recent_zset) of given video" do
      subject.should_receive(:adjust_relevance_of_recent_video).
        with(video, trigger.significance)
      subject.promote_video(video, trigger)
    end
  end

end
