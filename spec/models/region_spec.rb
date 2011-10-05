require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::Region do
    subject { Region.create }
    let(:channel) { stub("channel", :id=>1) }
    let(:channel2) { stub("channel", :id=>2) }

    context "After channels are added" do
      before(:each) do
        subject.feature_channel channel
        subject.feature_channel channel2
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

    describe "#feature_channel" do
      it "adds given channel into featured list" do
        expect { subject.feature_channel(channel) }.
          to change {subject.featured_channel_ids.count}.by(1)
        subject.featured_channel_ids.should include channel.id
      end
    end

    describe "#remove_feature" do
      it "removes given channel from featured list" do
        subject.feature_channel(channel)
        expect { subject.remove_channel(channel) }.
          to change { subject.featured_channel_ids.include? channel.id }.
          from(true).to(false)
      end
    end

    describe "#language_based" do
      it "returns the parent region based on language" do
        [:en, :ko].each do |code|
          region = Region.create :locale => "#{code}_xxx"
          region.language_based.should == (Region.send code)
        end
      end

      it "uses english based if there isn't a specific set of features for given language" do
        region = Region.create :locale => "zh_HK"
        region.language_based.should == Region.en
      end
    end

    describe "#master" do
      it "returns its master region based on language" do
        subject.master.should == subject.language_based
      end
    end

  end
end
