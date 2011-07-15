require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Queues::Mention::Parse do
    describe "#perform" do
      it "enqueues (to Process) or rejects a mention depending if mention has links or not" do
        ["twitter"].each do |source|
          data = mock("#{source} data")
          mention = mock("parsed #{source} data")
          Parsers::Tweet.stub(:parse).and_return(mention)
          
          mention.stub(:has_link?).and_return(true)
          Resque.should_receive(:enqueue).with(Queues::Mention::Process, mention)
          Queues::Mention::Parse.perform source, data
          
          mention.stub(:has_link?).and_return(false)
          Resque.should_receive(:enqueue).with(Queues::Mention::Process, mention).never
          Queues::Mention::Parse.perform source, data
        end
      end
    end
  end
end