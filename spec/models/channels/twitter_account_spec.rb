require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Channels::TwitterAccount do
  it 'sets a title' do
    Aji::Channels::TwitterAccount.find_or_create_by_account_id(
      Aji::ExternalAccounts::Twitter.find_or_create_by_uid(
        '_nuclearsammich').id).title.should == "@_nuclearsammich's channel"
  end

  describe "#populate" do
    it "adds videos recently shared" do
        pending "This will be a right cock in the ear to test without VCR"
    end

    context "when no vidoes are found in the first 50 tweets" do
      it "goes further back in the stream" do
        pending "This will be a right cock in the ear to test without VCR"
      end
    end
  end
end
