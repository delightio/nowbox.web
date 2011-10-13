require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Mixins::RecentVideos do
  # TODO Should move this to shared_examples
  subject { Aji::Channel::Trending.singleton }

  before :each do
    @videos = []
    5.times {|n| @videos << (mock("video", :id=>n))}
    @video = @videos.sample
    @videos.each do |v|
      Aji::Video.stub(:find_by_id).with(v.id).
        and_return(v)
    end
  end

  context "when asking for recent videos" do
    before(:each) do
      @limit = @videos.count/2
      @videos.each do |v|
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

  describe "#recent_relevance_of" do
    let(:video) { mock("video", :id=>100) }
    let(:relevance) { 23232 }

    it "returns relevance previously set" do
      subject.push_recent video, relevance
      subject.recent_relevance_of(video).should == relevance
    end
  end

  describe "#increment_relevance_of_recent_video" do
    let(:video) { mock "video", :id=>100 }
    let(:significance) { 545234 }

    it "increment the relevance of the given video by the given relevnace" do
      Aji.redis.should_receive(:zincrby).
        with(subject.recent_zset.key, significance, video.id)
      subject.increment_relevance_of_recent_video video, significance
    end
  end

  describe "#increment_all_scores_in_recent_videos" do
    let(:amount) { -10 }
    before (:each) do
      # 1 + v.id so we won't have 0 relevance
      @videos.each { |v| subject.push_recent v, (1+v.id)*100 }
    end

    it "adjusts all scores by given amount" do
      before_adj = subject.recent_videos.map{ |v| subject.recent_relevance_of v }
      subject.increment_relevance_in_all_recent_videos amount
      after_adj = subject.recent_videos.map{ |v| subject.recent_relevance_of v }
      before_adj.each_index do |i|
        (after_adj[i]-before_adj[i]).should == amount
      end
    end

    it "removes videos with below minimun relevance after adjustment" do
      min = -1 * amount
      subject.push_recent @video, min
      subject.increment_relevance_in_all_recent_videos amount, min
      subject.recent_video_ids.should_not include @video.id
    end

  end
end