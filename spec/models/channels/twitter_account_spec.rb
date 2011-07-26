require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Channels::TwitterAccount do
  it 'sets a title' do
    c = Aji::Channels::TwitterAccount.create(:account =>
      Aji::ExternalAccounts::Twitter.find_or_create_by_uid(
        '178492493', :user_info => { :nickname => '_nuclearsammich' }))
    c.title.should == "@_nuclearsammich's Tweeted Videos"
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
