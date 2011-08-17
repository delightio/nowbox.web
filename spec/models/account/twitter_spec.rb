require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Account::Twitter do
  subject { Aji::Account::Twitter.create(:uid => '178492493',
                                      :username => '_nuclearsammich') }

  describe "ALL THE OTHER METHODS"

  describe "#refresh_content" do
    it "adds videos recently shared" do
      expect { subject.refresh_content }.to(
        change(subject.content_zset, :members))
      subject.should be_populated
    end

    it "does not refresh within a short time" do
      subject.refresh_content
      expect { subject.refresh_content }.to_not change { subject.populated_at }
    end

    it "allows forced refresh" do
      subject.refresh_content
      expect { subject.refresh_content true }.to(
        change { subject.populated_at })
    end

    it "returns an array of Video objects" # TODO should combine with below
    it "always returns an array" do
      subject.refresh_content.should be_a_kind_of(Array)
      subject.refresh_content(true).should be_a_kind_of(Array)
      subject.refresh_content.should be_a_kind_of(Array)
    end

  end

  describe "#refresh_influencers" do
    it "adds twitter followers as influencers" do
      expect { subject.refresh_influencers }.to change(subject,
        :influencer_ids).from([])
    end
  end
end

