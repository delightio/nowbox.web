require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Queues::Mention::Parse do
    subject { Queues::Mention::Parse }

    describe "#perform" do
      before(:each) do
        @data = mock "raw data"
        @author = double("author", :blacklisted? => false)
        @mention = double("mention", :has_links? => true,
                                         :author => @author)
        Parsers::Tweet.stub(:parse).and_return(@mention)
      end

      it "enqueues to Queues::Mention::Process if mention has links" do
        Resque.should_receive(:enqueue).
          with(Queues::Mention::Process, @mention)
        subject.perform "twitter", @data
      end

      it "rejects given mention if there is no link" do
        @mention.stub(:has_links?).and_return(false)
        Resque.should_receive(:enqueue).
          with(Queues::Mention::Process, @mention).never
        subject.perform "twitter", @data
      end

      it "rejects given mention if author is blacklisted" do
        @author.stub(:blacklisted?).and_return(true)
        Resque.should_receive(:enqueue).
          with(Queues::Mention::Process, @mention).never
        subject.perform "twitter", @data
      end
    end
  end
end
