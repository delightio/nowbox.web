require File.expand_path("../../../spec_helper", __FILE__)
include Aji

describe Channel::Recommended do

  let(:account1) { Account::Youtube.create uid:'freddiew' }
  let(:account2) { Account::Youtube.create uid:'brentalfloss' }
  subject { Channel::Recommended.create accounts:[account1] }

  describe "#add_channel" do
    it "rejects non youtube channel" do
      bad = stub :youtube_channel? => false
      expect { subject.add_channel bad }.
        to_not change { subject.accounts }
    end

    it "adds given channel only once" do
      expect { subject.add_channel account1.to_channel }.
        to_not change { subject.accounts }
    end

    it "adds given channel to the list of channels for video recommendation" do
      expect { subject.add_channel account2.to_channel }.
        to change { subject.accounts.count }.by(1)
      subject.accounts.should == [account1, account2]
    end

  end

  describe "#remove_channel" do
    it "ignores input channel if it's non youtube channel" do
      bad = stub :youtube_channel? => false
      expect { subject.remove_channel bad }.
        to_not change { subject.accounts }
    end

    it "removes given channel from the list of channels for video recommendation" do
      expect { subject.remove_channel account1.to_channel }.
        to change { subject.accounts.count }.by(-1)
      subject.accounts.should be_empty
    end
  end

  describe "#available?" do
    it "is always unavailable for search" do
      subject.should_not be_available
    end
  end

end