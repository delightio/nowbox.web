require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Queues::Mention::Process do
    subject { Queues::Mention::Process }

    describe ".perform" do
      before :each do
        @data = stub("tweet data")
        @links_count_in_mention = 6
        @link = double("link", :external_id => 'someID12345',
                       :type => 'youtube', :video? => true)

        @links = Array.new(@links_count_in_mention, @link)
        # TODO: Don't use real author.
        @author = Account.new :uid => "someguy"
        @mention = double("mention", :videos => Array.new, :links => @links,
                          :save => true, :has_links? => true,
                          :author => @author, :spam? => false)

        @channel = double("channel", :id => 5)
        Aji::Channel.stub(:find).and_return(@channel)
        Parsers::Tweet.stub(:parse).and_return(@mention)
        Aji::Link.stub(:new).and_return(@link)
      end

      it "passes valid a valid channel and mention to a processor object" do
        MentionProcessor.should_receive(:new).with(@mention, @channel).
          and_return(mock('mention processor', :perform => true,
            :failed? => false))
        Queues::Mention::Process.perform 'twitter', @data, @channel.id
      end

      it "doesn't call Processor#perform if mention is nil" do
        MentionProcessor.should_not_receive :new
        Parsers::Tweet.stub(:parse).and_return nil
        Queues::Mention::Process.perform 'twitter', @data, @channel.id
      end
    end
  end
end
