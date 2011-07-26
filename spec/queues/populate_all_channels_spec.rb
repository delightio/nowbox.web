require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::Queues::PopulateAllChannels do
    before(:each) do
      @total = 10
      @channels = []
      @total.times { |n| @channels << (Factory :youtube_channel_with_videos) }
    end
    describe ".perform" do
      it "calls #populate on all existing channels" do
        Resque.should_receive(:enqueue).exactly(@total).times
        Queues::PopulateAllChannels.perform
      end
      
      it "returns if automatic population is turned off" do
        Queues::PopulateAllChannels.stub(:automatically?).and_return(false)
        Resque.should_receive(:enqueue).never
        Queues::PopulateAllChannels.perform
      end
    end
  
    describe ".automatically?" do
      it "returns true if no flag is set" do
        Aji.stub(:conf).and_return(Hash.new)
        Queues::PopulateAllChannels.automatically?.should == true
      end
      
      it "returns true if flag is set to false" do
        h = { 'PAUSE_AUTOMATIC_CHANNEL_POPULATION' => false }
        Aji.stub(:conf).and_return(h)
        Queues::PopulateAllChannels.automatically?.should == true
      end
    
      it "only returns false if flag is set" do
        h = { 'PAUSE_AUTOMATIC_CHANNEL_POPULATION' => true }
        Aji.stub(:conf).and_return(h)
        Queues::PopulateAllChannels.automatically?.should == false
      end
    end
  end
end