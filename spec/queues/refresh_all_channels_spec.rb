require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Queues::RefreshAllChannels do
    subject { Queues::RefreshAllChannels }

    describe ".perform" do
      it "returns if automatic population is turned off" do
        subject.stub(:automatically?).and_return(false)
        Resque.should_receive(:enqueue).never
        subject.perform
      end

      it "skips refreshing channels if more than half of the channels are still refreshing" do
        subject.stub(:backlogging?).and_return(true)
        Resque.should_receive(:enqueue).never
        subject.perform
      end

      it "does not refresh Trending and User channels" do
        Channel::Trending.should_receive(:all).never
        Channel::User.should_receive(:all).never
        subject.perform
      end

      it "only refreshes certain types of channels" do
        channel = mock("channel", :id=>1)
        channel_types = [ Channel::Account, Channel::Keyword,
          Channel::FacebookStream, Channel::TwitterStream]
        channel_types.each do |ch_class|
            ch_class.should_receive(:all).and_return([channel])
        end
        channel.should_receive(:background_refresh_content).
          exactly(channel_types.count).times

        subject.perform
      end
    end

    describe ".automatically?" do
      it "returns true if no flag is set" do
        Aji.stub(:conf).and_return(Hash.new)
        subject.automatically?.should == true
      end

      it "returns true if flag is set to false" do
        h = { 'PAUSE_AUTOMATIC_CHANNEL_POPULATION' => false }
        Aji.stub(:conf).and_return(h)
        subject.automatically?.should == true
      end

      it "only returns false if flag is set" do
        h = { 'PAUSE_AUTOMATIC_CHANNEL_POPULATION' => true }
        Aji.stub(:conf).and_return(h)
        subject.automatically?.should == false
      end
    end

    describe ".backlogging?" do
      before :each do
        Channel.stub(:count).and_return(20)
      end

      specify "true if we have a lot of jobs queued up" do
        Resque.stub(:size).and_return(1+Channel.count/2)
        subject.should be_backlogging
      end

      specify "false otherwise" do
        Resque.stub(:size).and_return(1)
        subject.should_not be_backlogging
      end
    end
  end
end