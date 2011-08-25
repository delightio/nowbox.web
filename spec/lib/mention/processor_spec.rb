require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Mention::Processor do

    describe "#perform" do
      before :each do
        @destination = mock("video destination")
        @link_count = 2
        @video = mock("video", :blacklisted? => false)
        @link = mock("video link", :to_video => @video)
        @links = Array.new(@link_count, @link)
        @author = mock("author", :blacklisted? => false, :save => true)
        @mention_videos = Array.new
        @mention = mock("mention", :author => @author, :spam? => false,
          :links => @links, :videos => @mention_videos, :text => "",
          :save => true)
      end

      subject { Mention::Processor.new @mention, @destination }


      it "places all videos in their destination" do
        @destination.should_receive(:push_recent).exactly(@link_count).times
        subject.perform
      end

      it "doesn't use videos from blacklisted authors" do
        @author.stub(:blacklisted?).and_return true
        @destination.should_not_receive :push_recent
        subject.perform
      end

      it "blacklists spamming authors" do
        @mention.stub(:spam?).and_return(true)
        video = double("video", :blacklisted? => false)
        @destination.should_receive(:push_recent).never
        @mention.author.should_receive :blacklist
        subject.perform
      end
    end

    describe ".video_filters" do
      it "returns a hash of lambdas" do
        filters = Mention::Processor.video_filters
        filters.values.each do |f| f.class.should == Proc end
      end
    end
  end
end
