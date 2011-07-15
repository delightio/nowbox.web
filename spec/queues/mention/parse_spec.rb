require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Queues::Mention::Parse do
    subject { Queues::Mention::Parse }
    
    describe "#perform" do
      before(:each) do
        @data = mock "raw data"
        @author = double("author", :is_blacklisted? => false)
        @mention = double("parsed data", :has_link? => true,
                                         :author => @author)
        Parsers::Tweet.stub(:parse).and_return(@mention)
      end
      
      it "enqueues to Queues::Mention::Process if mention has links" do
        Resque.should_receive(:enqueue).with(Queues::Mention::Process, @mention)
        subject.perform "twitter", @data
      end
      
      it "rejects given mention if there is no link" do
        @mention.stub(:has_link?).and_return(false)
        Resque.should_receive(:enqueue).with(Queues::Mention::Process, @mention).never
        subject.perform "twitter", @data
      end
      
      it "rejects given mention if author is blacklisted" do
        author = double("blacklisted author", :is_blacklisted? => true)
        mention = double("parsed data", :has_link? => true,
                                        :author => author)
        Parsers::Tweet.stub(:parse).and_return(mention)
        # @author.stub(:is_blacklisted?).and_return(true) # TODO: isn't this all I need?
        Resque.should_receive(:enqueue).with(Queues::Mention::Process, mention).never
        subject.perform "twitter", @data
      end
    end
  end
end