require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Mixins::RecentVideos do
  # TODO Should move this to shared_examples
  subject { Aji::Channel::Trending.singleton }

  describe "#push_recent" do
    it "increments the number of recent_video_ids" do
      expect { subject.push_recent(Factory :video) }.to
        change { subject.recent_video_ids.count }.by(1)
    end
    it "adds given video into recent_video_ids" do
      video = Factory :video
      expect { subject.push_recent video }.to
        change { subject.recent_video_ids.include? video.id }.to(true)
    end
    it "should only keep given number of mentioned videos" do
      n = 2
      Aji.stub(:conf).and_return({'MAX_RECENT_VIDEO_IDS_IN_TRENDING'=>n})
      (n*2).times {|k| subject.push_recent(Factory :video)}
      subject.recent_video_ids.count.should == n
    end    
  end

  describe "#pop_recent" do
    before(:each) do
      5.times { subject.push_recent(Factory :video) }
      @video = Aji::Video.find(subject.recent_video_ids.sample)
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