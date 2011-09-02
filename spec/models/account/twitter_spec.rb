require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Account::Twitter do
  subject { Aji::Account::Twitter.create(:uid => '178492493',
                                      :username => '_nuclearsammich') }

  it_behaves_like "any account"
  it_behaves_like "any content holder"

  describe "#refresh_influencers" do
    it "adds twitter followers as influencers" do
      expect { subject.refresh_influencers }.to change(subject,
        :influencer_ids).from([])
    end
  end

  describe "#mark_spammer" do
    it "marks own mentions as spam and destroys them" do
      mention = mock("mention")
      mention.should_receive :mark_spam
      mention.should_receive :destroy
      subject.stub(:mentions).and_return([mention])
      subject.mark_spammer
    end
  end
end
