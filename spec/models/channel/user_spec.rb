require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Aji::Channel::User do
    subject do
      Channel::User.new.tap do |c|
        c.stub :id => 1
      end
    end

    describe "#thumbnail_uri" do
      it "picks the appropriate image for the channel based on title" do
        Channel::User.new(:title => "Watch Later").thumbnail_uri.should(
          match /watch_later\.png/)
        Channel::User.new(:title => "Favorites").thumbnail_uri.should(
          match /favorites\.png/)
        Channel::User.new(:title => "History").thumbnail_uri.should(
          match /history\.png/)
      end
    end

    describe "#merge!" do
      subject do
        Channel::User.new.tap do |c|
          c.stub :id => 1
          c.stub :events => []
          content_videos.each do |v|
            c.content_zset[v.id] = v.id
          end
        end
      end

      let(:content_videos) do
        (1..5).map do |i|
          mock("video", :id => i).tap do |c|
            Video.stub(:find_by_id).with(c.id).and_return(c)
          end
        end
      end

      let(:other_channel) do
        Channel::User.new.tap do |c|
          c.stub :id => 2
          c.stub :content_videos => ((6..10).map do |i|
            c.content_zset[i] = i
            mock("video", :id => i).tap do |v|
              Video.stub(:find_by_id).with(i).and_return(v)
            end
          end)
          c.stub(:events => [ mock("event") ])
          (3..4).each{ |i| c.category_id_zset[i] = i }
        end
      end

      it "adds content from other channel" do
        subject.merge! other_channel

        other_channel.content_videos.each do |v|
          subject.has_content_video?(v).should be_true
        end
      end

      it "preserves scores of videos in both channels" do
        subject.merge! other_channel

        content_videos.each do |v|
          subject.content_zset[v.id].should == v.id
        end
      end

      it "adds categories from the other channel preserving their scores" do
        subject.merge! other_channel
        other_channel.category_id_zset.members(:with_scores => true).
          each do |(cid, score)|
          subject.category_id_zset[cid].should == score
        end
      end


      it "adds events from the other channel" do
        subject.merge! other_channel

        other_channel.events.each do |ev|
          subject.events.should include ev
        end
      end

      it "returns true if it saves successfully" do
        subject.merge!(other_channel).should be_true
      end
    end
  end
end
