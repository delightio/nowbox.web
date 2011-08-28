require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Mixins::ContentVideos do
  subject { Aji::Channel.create }

  context "when a limit parameter is not passed in" do
    before(:each) do
      @total = 10
      @total.times { subject.push(Factory :video) }
    end
    [:content_video_ids, :content_videos].each do |m|
      specify "##{m} returns all videos" do
        subject.send(m).should have(@total).videos
      end
    end
  end

  context "when a limit parameter is passed in" do
    before(:each) do
      10.times { subject.push(Factory :video) }
      @limit = 5
    end
    specify "#content_video_ids respects the limit" do
      subject.content_video_ids.should have(10).videos
      subject.content_video_ids(@limit).should have(@limit).videos
    end
    specify "#content_videos respects the limit" do
      subject.content_videos(@limit).should have(@limit).videos
    end
  end

  describe "#push" do
    it "increments the number of content_videos" do
      expect { subject.push(Factory :video) }.to
        change { subject.content_videos.count }.by(1)
    end
    it "adds given video into content_video" do
      video = Factory :video
      expect { subject.push video }.to
        change { subject.content_videos.include? video }.to(true)
    end
  end

  describe "#pop" do
    before(:each) do
      5.times { subject.push(Factory :video) }
      @video = subject.content_videos.sample
    end
    it "decrements the number of content_videos" do
      expect { subject.pop @video }.to
        change { subject.content_videos.count }.by(1)
    end
    it "removes video from content_video" do
      expect { subject.pop @video }.to
        change { subject.content_videos.include? @video }.to(false)
    end
  end

  describe "#relevance_of" do 
    it "returns the score used when pushed" do
      relevance = rand(100).seconds.ago.to_i
      video = Factory :video
      subject.push video, relevance
      subject.relevance_of(video).should == relevance
    end
  end

  describe "#truncate" do
    it "truncates elements from lowest scores to keep given size" do
      5.times { subject.push Factory(:video), rand(100).seconds.ago.to_i }
      expect { subject.truncate 4 }.to
        change { subject.content_videos }.from(5).to(4)
      scores = subject.content_videos.map {|v| subject.relevance_of v }
      subject.relevance_of(subject.content_videos.first).should == scores.max
      subject.relevance_of(subject.content_videos.last).should == scores.min
    end
  end
end