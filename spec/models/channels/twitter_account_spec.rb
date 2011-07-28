require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Channels::TwitterAccount do
  it 'sets a title' do
    Aji::Channels::TwitterAccount.create(:account =>
      Aji::ExternalAccounts::Twitter.find_or_create_by_uid(
        '178492493', :username => '_nuclearsammich')).title.
        should == "@_nuclearsammich's Tweeted Videos"
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

    describe ".find_or_create_by_account" do
      before :each do
        @twitter_user = Aji::ExternalAccounts::Twitter.create :uid =>
          '178492493', :username => '_nuclearsammich'
      end

      context "when the channel exists" do
        it "returns the existing channel" do
          @twitter_user.channel = Aji::Channels::TwitterAccount.create(
            :account => @twitter_user)
          Aji::Channels::TwitterAccount.find_or_create_by_account(@twitter_user).
            should == @twitter_user.channel
        end
      end

      context "when the channel doesn't exist" do
        it "creates a new channel" do
          expect do
            Aji::Channels::TwitterAccount.
              find_or_create_by_account(@twitter_user)
          end.to change(Aji::Channels::TwitterAccount, :count).by(1)
        end
      end
    end
  end
end
