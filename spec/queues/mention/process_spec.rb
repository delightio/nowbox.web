require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Queues::Mention::Process do
    subject { Queues::Mention::Process }

    describe ".parse" do
      before(:each) do
        @data = mock "raw data"
        @author = double("author", :blacklisted? => false)
        @mention = double("mention", :has_links? => true,
          :author => @author)
        Parsers::Tweet.stub(:parse).and_return(@mention)
      end

      context "when given a valid tweet" do
        it "returns a valid mention" do
          pending
          mention = subject.parse("twitter", @data)
          mention.class.should == Aji::Mention
          mention.errors.should be_empty
        end
      end

      context "when given data from an unknown source" do
        it "returns nil" do
          subject.parse('unknown', 'data').should be_nil
        end
      end
    end


    describe ".perform" do
      before(:each) do
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
        Aji::Queues::Mention::Process.stub(:parse).and_return(@mention)
        Aji::Link.stub(:new).and_return(@link)
      end

      it "pushes all videos mentioned into trending channel" do
        video = double("video", :blacklisted? => false)
        Aji::Video.should_receive(:find_or_create_by_external_id_and_source)
          .exactly(@links_count_in_mention).times
          .and_return(video)
        @channel.should_receive(:push_recent).
          exactly(@links_count_in_mention).times
        subject.perform 'twitter', mock("tweet data"), @channel.id
      end

      it "blacklists author who mentions a blacklisted video" do
        bad_author = mock("bad author", :blacklisted? => false)
        @mention.stub(:author).and_return(bad_author)
        blacklisted_video = double("blacklisted video", :blacklisted? => true)
        Aji::Video.stub(:find_or_create_by_external_id_and_source).
          and_return(blacklisted_video)
        bad_author.should_receive(:blacklist).at_least(1)
        @channel.should_receive(:push_recent).never
        subject.perform 'twitter', @data, @channel.id
      end

      it "blacklists author who mentions same set of video multiple times" do
        @mention.stub(:spam?).and_return(true)
        video = double("video", :blacklisted? => false)
        Aji::Video.stub(:find_or_create_by_external_id_and_source).and_return(video)
        @channel.should_receive(:push_recent).never
        subject.perform 'twitter', @data, @channel.id
        @mention.author.should be_blacklisted
      end

      it "rejects given mention if there is no link" do
        @mention.stub(:has_links?).and_return(false)
        @mention.should_receive(:links).never
        subject.perform "twitter", @data, @channel.id
      end

      context "when a link does not point to a video" do
        it "does not try to create a video object"
      end
    end
  end
end
