require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Account::Twitter do
  subject { Aji::Account::Twitter.create(:uid => '178492493',
                                      :username => '_nuclearsammich') }

  it_behaves_like "any account"
  it_behaves_like "any content holder"

  describe "ALL THE OTHER METHODS"

  describe "#refresh_influencers" do
    it "adds twitter followers as influencers" do
      expect { subject.refresh_influencers }.to change(subject,
        :influencer_ids).from([])
    end
  end
end

