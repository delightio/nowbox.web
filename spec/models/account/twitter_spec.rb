require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Account::Twitter do
  subject { Aji::Account::Twitter.create(:uid => '178492493',
                                      :username => '_nuclearsammich') }

  it_behaves_like "any account"

  describe "#refresh_influencers" do
    it "adds twitter followers as influencers" do
      expect { subject.refresh_influencers }.to change(subject,
        :influencer_ids).from([])
    end
  end

  describe "#mark_spammer" do
    it "marks own mentions as spam and destroys them" do
      videos = mock("video collection")
      videos.stub(:map).and_return([])
      mention = mock("mention", :id => 9, :spam? => true, :videos => videos)
      mention.should_receive :mark_spam
      mention.should_receive :destroy
      subject.stub(:mentions).and_return([mention])
      subject.mark_spammer
    end

    it "blacklists self" do
      subject.should_receive(:blacklist)
      subject.mark_spammer
    end
  end
end
