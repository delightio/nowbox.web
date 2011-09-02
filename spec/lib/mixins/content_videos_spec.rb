require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Mixins::ContentVideos do
  subject { Aji::Channel.create }

  context "when asking for content" do
    before(:each) do
      @total = 10
      @total.times { subject.push(Factory :video) }
      @limit = 5
    end

    describe "when a limit parameter is not passed in" do
      [ :content_video_ids, :content_videos,
        :content_video_ids_rev, :content_videos_rev].each do |m|
        specify "##{m} returns all videos" do
          subject.send(m).should have(@total).videos
        end
      end
    end

    context "when a limit parameter is passed in" do
      [ :content_video_ids, :content_videos,
        :content_video_ids_rev, :content_videos_rev].each do |m|
        specify "##{m} respects the limit" do
          subject.send(m, @limit).should have(@limit).videos
        end
      end
    end
  end

  describe "#content_video_ids_rev" do
    it "returns content in ascending order" do
      5.times { |n| subject.push (Factory :video), n }
      subject.relevance_of(
        Aji::Video.find(subject.content_video_ids_rev.first)).
        should == 0
      subject.relevance_of(
        Aji::Video.find(subject.content_video_ids_rev.last)).
        should == 4
    end
  end

  describe "#content_video_ids" do
    it "returns content in descending order" do
      5.times { |n| subject.push (Factory :video), n }
      subject.relevance_of(
        Aji::Video.find(subject.content_video_ids.first)).
        should == 4
      subject.relevance_of(
        Aji::Video.find(subject.content_video_ids.last)).
        should == 0
    end
  end

  describe "#content_video_id_count" do
    it "returns the number of video ids in content_zset" do
      expect { subject.push(mock("video",:id=>1)) }.
        to change { subject.content_video_id_count }.by(1)
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