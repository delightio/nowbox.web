require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Queues::Mention::Process do
    subject { Queues::Mention::Process }
    describe "#perform" do
      it "pushes all videos mentioned into trending channel" do
        links_count_in_mention = rand 10
        link = double("link", :youtube_id => :anything,
                              :type => :anything)
        links = Array.new(links_count_in_mention, link)
        mention = double("mention", :videos => Array.new, 
                                    :links => links,
                                    :save => true)
        Aji::Mention.stub(:new).and_return(mention)
        Aji::Link.stub(:new).and_return(link)
        Aji::Video.should_receive(:find_or_create_by_external_id_and_source).exactly(links_count_in_mention).times

        trending = mock "trending channel"
        Aji::Channels::Trending.stub(:first).and_return(trending)
        trending.should_receive(:push_recent).exactly(links_count_in_mention).times
        subject.perform :anything
      end
    end
  end
end
