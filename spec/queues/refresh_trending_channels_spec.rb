require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Queues::RefreshTrendingChannels do
    subject { Queues::RefreshTrendingChannels }

    describe ".perform" do
      it "refreshes every trending channels" do
        channels = Array.new(5, mock)
        channels.each { |c| c.should_receive(:background_refresh_content) }
        Channel::Trending.stub(:all).and_return(channels)
        subject.perform
      end
    end

  end
end