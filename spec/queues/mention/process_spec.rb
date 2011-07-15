require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Queues::Mention::Process do
    subject { Queues::Mention::Process }
    describe "#perform" do
      before(:each) do
        @links_count_in_mention = rand 10
        @link = double("link", :youtube_id => :anything,
                               :type => :anything)
        @links = Array.new(@links_count_in_mention, @link)
        @mention = double("mention", :videos => Array.new,
                                    :links => @links,
                                    :save => true)
        Aji::Mention.stub(:new).and_return(@mention)
        Aji::Link.stub(:new).and_return(@link)
        
        @trending = mock "trending channel"
        Aji::Channels::Trending.stub(:first).and_return(@trending)
      end
      
      it "pushes all videos mentioned into trending channel" do
        video = double("video", :is_blacklisted? => false)
        Aji::Video.should_receive(:find_or_create_by_external_id_and_source)
          .exactly(@links_count_in_mention).times
          .and_return(video)
        @trending.should_receive(:push_recent).exactly(@links_count_in_mention).times
        subject.perform :anything
      end
      
      it "only pushes non-blackisted videos into trending channel" do
        blacklisted_video = double("blacklisted video", :is_blacklisted? => true)
        Aji::Video.should_receive(:find_or_create_by_external_id_and_source)
          .exactly(@links_count_in_mention).times
          .and_return(blacklisted_video)
        @trending.should_receive(:push_recent).never
        subject.perform :anything
      end
    end
  end
end
