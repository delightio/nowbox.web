require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe MentionProcessor do

    describe "#perform" do
      before :each do
        @destination = mock("video destination")
        @link_count = 2
        @video = mock("video", :blacklisted? => false)
        @link = mock("video link", :to_video => @video)
        @links = Array.new(@link_count, @link)
        @author = mock("author", :blacklisted? => false, :save => true,
          :username => "blah", :id => 1)
        @mention_videos = Array.new
        @mention = mock("mention", :author => @author, :spam? => false,
          :links => @links, :videos => @mention_videos, :body => "",
          :published_at => Time.now, :save => true, :id => 1)
      end

      subject { MentionProcessor.new @mention, @destination }


      it "places all videos in their destination" do
        @destination.should_receive(:push_recent).exactly(@link_count).times
        subject.perform
      end

      it "blacklists spamming authors and everything it touches" do
        @mention.stub(:spam?).and_return(true)
        Resque.should_receive(:enqueue).with(Queues::RemoveSpammer,
           @mention.author.id)
        subject.perform
      end
    end

    describe ".video_filters" do
      it "returns a hash of lambdas" do
        filters = MentionProcessor.video_filters
        filters.values.each do |f| f.class.should == Proc end
      end
    end
  end
end
