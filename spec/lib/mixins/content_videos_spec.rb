require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Aji::Mixins::ContentVideos, :unit do
    #  A class with the minimum necessary to act as a content holder.
    class ContentVideoHolder
      include Redis::Objects
      include Mixins::ContentVideos

      attr_reader :id

      def initialize
        @id = self.class.next_id
      end

      def self.next_id
        @last_id = @last_id.to_i + 1
      end
    end

    subject { ContentVideoHolder.new }

    # # Cannot be lazily initialized use let-bang.
    # Cannot be lazily initialized use let-bang.
    let!(:videos) do
      (1..5).map do |i|
        mock("video").tap do |v|
          v.stub :id => i
          Video.stub(:find_by_id).with(i).and_return(v)
          subject.push v, i
        end
      end
    end

    context "when asking for content" do
      let(:total) { videos.size }
      let(:limit) { videos.size - 3 }

      describe "when a limit parameter is not passed in" do
        [ :content_video_ids, :content_videos,
          :content_video_ids_rev, :content_videos_rev].each do |m|
            specify "##{m} returns all videos" do
              subject.send(m).should have(total).videos
            end
          end
      end

      context "when a limit parameter is passed in" do
        [ :content_video_ids, :content_videos,
          :content_video_ids_rev, :content_videos_rev].each do |m|
          specify "##{m} respects the limit" do
            subject.send(m, limit).should have(limit).videos,
              "expected ##{m} to return #{limit} videos, got " +
              subject.send(m, limit).size.to_s
          end
          end
      end
    end

    describe "#content_video_ids_rev" do
      it "returns content in ascending order" do
        subject.content_video_ids_rev.should == [ 1, 2, 3, 4, 5 ]
      end
    end

    describe "#content_video_ids" do
      it "returns content in descending order" do
        subject.content_video_ids.should == [ 5, 4, 3, 2, 1 ]
      end
    end

    describe "#content_video_id_count" do
      it "returns the number of video ids in content_zset" do
        expect { subject.push mock("video", :id => 9) }.
         to change(subject, :content_video_id_count).by(1)
      end
    end

    describe "#push" do
      let(:video) do
        mock("video", :id => 6).tap do |v|
          Video.stub(:find_by_id).with(v.id).and_return(v)
        end
      end

      it "increments the number of content_videos" do
        expect { subject.push video }.to change(subject, :content_videos)
      end

      it "adds given video into content_video" do
        expect { subject.push video }.to(
          change { subject.content_videos.include? video }.to(true))
      end
    end

    describe "#pop" do
      let(:video) { subject.content_videos.sample }

      it "decrements the number of content_videos" do
        expect { subject.pop video }.to(
          change { subject.content_videos.count }.by(-1))
      end

      it "removes video from content_video" do
        expect { subject.pop video }.to(
        change { subject.content_videos.include? video }.to(false))
      end
    end

    describe "#relevance_of" do
      it "returns the score used when pushed" do
        relevance = rand(100).seconds.ago.to_i
        video = mock("video", :id => 6)
        subject.push video, relevance
        subject.relevance_of(video).should == relevance
      end
    end

    describe "#truncate" do
      it "truncates elements from lowest scores to keep given size" do
        expect { subject.truncate 4 }.to(
        change { subject.content_video_id_count }.from(5).to(4))
        scores = subject.content_videos.map {|v| subject.relevance_of v }
        subject.relevance_of(subject.content_videos.first).should == scores.max
        subject.relevance_of(subject.content_videos.last).should == scores.min
      end
    end

      describe "#has_content_video?" do
        let(:video) { mock "video", :id=> 99 }

      it "is false if we don't have a score with given video" do
        subject.has_content_video?(video).should be_false
      end

      it "is true if we already have it in content_video zset" do
        subject.push video
        subject.has_content_video?(video).should be_true
      end
    end
  end
end
