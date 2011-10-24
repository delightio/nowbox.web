require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe MentionProcessor, :unit do
    describe "#perform" do

      let(:destination) { mock "video destination" }
      let(:video_1) { mock "video", :blacklisted? => false }
      let(:video_2) { mock "video", :blacklisted? => false }
      let(:link)  { mock "video link", :to_video => video }
      let(:links) { [stub(:to_video => video_1), stub(:to_video => video_2)] }

      let(:author) do
        mock "author", :blacklisted? => false, :save => true,
          :username => "blah", :id => 1, :push => true
      end

      let(:mention) do
        mock "mention", :spam? => false, :links => links, :author => author,
          :body => "", :videos => [], :save => true, :id => 1,
          :published_at => Time.now
      end

      subject { MentionProcessor.new mention, destination }

      it "promotes videos mentioned" do
        links.map(&:to_video).each do |video|
          destination.should_receive(:promote_video).with(video, mention)
        end

        subject.perform
      end

      it "blacklists spamming authors and everything it touches" do
        mention.stub(:spam?).and_return(true)
        Resque.should_receive(:enqueue).with(Queues::RemoveSpammer,
           mention.author.id)

        subject.perform
      end

       it "adds found videos to author's content" do
         links.map(&:to_video).each do |video|
           author.should_receive(:push).with(video)
         end

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
