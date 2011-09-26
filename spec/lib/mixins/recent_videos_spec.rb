require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Mixins::RecentVideos do
  # TODO Should move this to shared_examples
  subject { Aji::Channel::Trending.singleton }

  before :each do
    @videos = []
    5.times {|n| @videos << (mock("video", :id=>n))}
    @video = @videos.sample
  end

  context "when asking for recent videos" do
    before(:each) do
      @limit = @videos.count/2
      @videos.each do |v|
        Aji::Video.stub(:find_by_id).with(v.id).
          and_return(v)
        subject.push_recent v
      end
    end

    describe "when a limit parameter is not passed in" do
      [ :recent_videos, :recent_video_ids].each do |m|
        specify "##{m} returns all videos" do
          subject.send(m).should have(@videos.count).videos
        end
      end
    end

    context "when a limit parameter is passed in" do
      [ :recent_videos, :recent_video_ids].each do |m|
        specify "##{m} respects the limit" do
          subject.send(m, @limit).should have(@limit).videos
        end
      end
    end
  end

  describe "#push_recent" do
    it "increments the number of recent_video_ids" do
      expect { subject.push_recent(@video) }.to
        change { subject.recent_video_ids.count }.by(1)
    end
    it "adds given video into recent_video_ids" do
      expect { subject.push_recent @video }.to
        change { subject.recent_video_ids.include? @video.id }.to(true)
    end
    it "should only keep given number of mentioned videos" do
      n = 2
      Aji.stub(:conf).and_return({'MAX_RECENT_VIDEO_IDS_IN_TRENDING'=>n})
      (n*2).times {|k| subject.push_recent(@videos[k])}
      subject.recent_video_ids.count.should == n
    end    
  end

  describe "#pop_recent" do
    before(:each) do
      @videos.each {|v| subject.push_recent v }
    end
    it "decrements the number of recent_video_ids" do
      expect { subject.pop_recent @video }.to
        change { subject.recent_video_ids.count }.by(1)
    end
    it "removes video from recent_video_ids" do
      expect { subject.pop_recent @video }.to
        change { subject.recent_video_ids.include? @video.id }.to(false)
    end
  end
end