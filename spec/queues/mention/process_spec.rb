require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Queues::Mention::Process do
    subject { Queues::Mention::Process }
    describe "#perform" do
      before(:each) do
        @links_count_in_mention = rand 10
        @link = double("link", :external_id => 'someID12345',
                               :type => 'youtube')
        @links = Array.new(@links_count_in_mention, @link)
        @author = ExternalAccount.new
        @mention = double("mention", :videos => Array.new,
                                     :links => @links,
                                     :save => true,
                                     :author => @author,
                                     :spam? => false)
        Aji::Mention.stub(:new).and_return(@mention)
        Aji::Link.stub(:new).and_return(@link)
        @trending = mock "trending channel"
        Aji::Channels::Trending.stub(:first).and_return(@trending)
      end

      it "pushes all videos mentioned into trending channel" do
        video = double("video", :blacklisted? => false)
        Aji::Video.should_receive(:find_or_create_by_external_id_and_source)
          .exactly(@links_count_in_mention).times
          .and_return(video)
        @trending.should_receive(:push_recent).
          exactly(@links_count_in_mention).times
        mention_hash = mock('mention hash')
        mention_hash.should_receive(:"[]").and_return(mock('mention params'))
        subject.perform mention_hash
      end

      it "blacklists author who mentions a blacklisted video" do
        bad_author = ExternalAccount.new
        @mention.stub(:author).and_return(bad_author)
        blacklisted_video = double("blacklisted video", :blacklisted? => true)
        Aji::Video.stub(:find_or_create_by_external_id_and_source).and_return(blacklisted_video)
        @trending.should_receive(:push_recent).never
        subject.perform :anything
        bad_author.should be_blacklisted
      end

      it "blacklists author who mentions same set of video multiple times" do
        @mention.stub(:spam?).and_return(true)
        video = double("video", :blacklisted? => false)
        Aji::Video.stub(:find_or_create_by_external_id_and_source).and_return(video)
        @trending.should_receive(:push_recent).never
        subject.perform :anything
        @mention.author.should be_blacklisted
      end

    end
  end
end
