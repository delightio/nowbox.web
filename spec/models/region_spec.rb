require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::Region do
    subject { Region.create }
    let(:channel) { stub("channel", :id=>1) }
    let(:channel2) { stub("channel", :id=>2) }

    context "After channels are added" do
      before(:each) do
        subject.add_featured_channel channel
        subject.add_featured_channel channel2
      end

      it "#featured_channels returns feature channel objects" do
        Channel.stub(:find_by_id).with(channel.id).and_return(channel)
        Channel.stub(:find_by_id).with(channel2.id).and_return(channel2)
        subject.featured_channels.should == [channel, channel2]
      end

      it "#featured_channel_ids returns featured channels as in the order added." do
        subject.featured_channel_ids.should == [channel.id, channel2.id]
      end
    end

    describe "#add_featured_channel" do
      it "adds given channel into featured list" do
        expect { subject.add_featured_channel(channel) }.
          to change {subject.featured_channel_ids.count}.by(1)
        subject.featured_channel_ids.should include channel.id
      end
    end

    describe "remove_feature" do
      it "removes given channel from featured list" do
        subject.add_featured_channel(channel)
        expect { subject.remove_featured_channel(channel) }.
          to change { subject.featured_channel_ids.include? channel.id }.
          from(true).to(false)
      end
    end

  end
end
