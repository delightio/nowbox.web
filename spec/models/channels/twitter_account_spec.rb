require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Channels::TwitterAccount do
  before :each do
    @twitter_account = Aji::Account::Twitter.create(
      :uid => '178492493',
      :username => '_nuclearsammich')
  end
  subject { Aji::Channels::TwitterAccount.create :account => @twitter_account }

  it 'sets a title' do
    Aji::Channels::TwitterAccount.create(:account =>
        @twitter_account).title.should == "@_nuclearsammich's Tweeted Videos"
  end

  describe "#find_or_create_by_username" do
    it "returns un-populated channel by default" do
      subject.should_not be_populated
    end

    it "populates new channel when asked", :network => true do
      new_channel = Aji::Channels::TwitterAccount.find_or_create_by_account(
      @twitter_account, :populate_if_new => true)
      Aji::Channel.find(new_channel.id).should be_populated
    end
  end

  describe "#populate", :network => true do

    it "does not re populate within short time" do
      subject.populate
      expect { subject.populate }.to_not change { subject.populated_at }
    end

    it "allows forced population" do
      subject.populate
      expect { subject.populate(:must_populate=>true) }.to(
        change { subject.populated_at })
    end

    it "adds videos recently shared" do
        channel = Aji::Channels::TwitterAccount.create(
         :account => @twitter_account)
        #channel.content_videos.count.should == 0
        expect { channel.populate }.to change(channel.content_zset, :members)
        #channel.content_videos.count.should > 0
    end

    context "when no vidoes are found in the first 50 tweets" do
      it "goes further back in the stream" do
        pending "This will be a right cock in the ear to test without VCR"
      end
    end

    describe ".find_or_create_by_account" do
      before :each do
        @twitter_user = Aji::Account::Twitter.create :uid =>
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
