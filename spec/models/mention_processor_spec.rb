require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe MentionProcessor, :unit do
    describe "#perform" do

      let(:destination) { mock "video destination" }
      let(:video) { mock "video", :blacklisted? => false }
      let(:link)  { mock "video link", :to_video => video }
      let(:link_count) { 2 }
      let(:links) { Array.new link_count, link }
      let(:author) do
        mock "author", :blacklisted? => false, :save => true,
          :username => "blah", :id => 1
      end
      let(:mention) do
        mock "mention", :spam? => false, :links => links, :author => author,
          :body => "", :videos => [], :save => true, :id => 1,
          :published_at => Time.now
      end

      subject { MentionProcessor.new mention, destination }

      it "promotes videos mentioned" do
        destination.should_receive(:promote_video).
          with(video, mention).
          exactly(link_count).times
        subject.perform
      end

      it "blacklists spamming authors and everything it touches" do
        mention.stub(:spam?).and_return(true)
        Resque.should_receive(:enqueue).with(Queues::RemoveSpammer,
           mention.author.id)
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
