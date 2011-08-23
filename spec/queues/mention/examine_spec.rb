require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Queues::Mention::Examine do
    subject { Queues::Mention::Examine }
    describe ".perform" do
      it "re enqueue the problematic mention back to Mention::Process" do
        source = 'Twitter'
        data = mock 'data'
        channel = mock 'channel'
        Resque.should_receive(:enqueue).with(
          Queues::Mention::Process, source, data, channel).once
        subject.perform source, data, channel
      end
    end
  end
end