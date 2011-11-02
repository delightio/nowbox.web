require File.expand_path("../../spec_helper", __FILE__)

include Aji

describe Queues::DistributdRefreshAllChannels do
  subject { Queues::DistributdRefreshAllChannels }
  describe ".perform" do
    it "each channel type evenly across the time window" do
      mock("channel type", :select => [mock("channel", :id => 1)])
      Channel.stub :autopopulatable_types => channel_class

      subject.perform
    end
  end
end

