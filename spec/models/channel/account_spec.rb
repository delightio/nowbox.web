require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Channel::Account do
    before(:each) do
      @accounts = (0..2).map { Factory :youtube_account }
    end

    subject { Channel::Account.find_or_create_by_accounts @accounts }

    it "should set title based on accounts" do
      accounts = %w{foo bar baz}.map{|n| Account::Youtube.create uid: n}
      subject = Channel::Account.create :accounts => accounts
      subject.title.should == "foo's, bar's, baz's Videos"
    end

    describe "#refresh_content" do
      it "fetches videos from youtube" do
        youtube_account = Account::Youtube.create :uid => "nicnicolecole"
        c = Channel::Account.create :accounts => [youtube_account]
        expect { c.refresh_content }.to change(c, :content_video_ids).from([])
      end

      it "does not refresh within short time" do
        real_youtube_users = ["nowmov", "cnn", "freddiew"].map do |uid|
          Account::Youtube.create :uid => uid
        end

        subject = Channel::Account.create :accounts => real_youtube_users
        subject.refresh_content
        subject.should_not_receive(:save)
        subject.refresh_content
      end

      it "allows forced refresh" do
        real_youtube_users = ["nowmov", "cnn", "freddiew"].map do |uid|
          Account::Youtube.create :uid => uid
        end

        subject = Channel::Account.create :accounts => real_youtube_users
        subject.refresh_content
        subject.accounts.each{ |a| a.should_receive(:refresh_content).once.
          and_return([]) }
        subject.refresh_content true
      end

      it "waits for the lock before populating"
    end

    # TODO: Refactor using context block to show Thomas
    describe ".find_or_create_by_accounts" do
      it "returns a new channel when there is no exact match" do
        subject = Channel::Account.find_or_create_by_accounts @accounts
        subject.class.should == Channel::Account
        accounts = @accounts -  Array(@accounts.sample)
        new_channel = Channel::Account.find_or_create_by_accounts accounts
        new_channel.should_not == subject
      end

      it "returns same channel when we find an existing channel with given usernames" do
        accounts = %w(machinima freddegredde).map{|n| Account::Youtube.create(
          :uid => n)}
        channel = Channel::Account.find_or_create_by_accounts accounts
        found_channel = Channel::Account.find_or_create_by_accounts accounts
        found_channel.should == channel
      end

      it "returns a channel with given youtube accounts" do
        subject.accounts.should == @accounts
      end

      it "returns unpopulated channel by default" do
        subject.should_not be_populated
      end

      it "populates new channel when asked" do
        accounts = Array(Account::Youtube.create uid: "noexists")
        new_channel = Channel::Account.find_or_create_by_accounts accounts, {},
          true
        new_channel.should be_populated
      end

      it "passes initial parameters to .create" do
        test_title = random_string
        h = {:default_listing => true}
        ch = Channel::Account.find_or_create_by_accounts(@accounts, h)
        Channel.find(ch.id).default_listing.should == true
      end

      it "works with account which never has a channel on our system" do
        account_array = Array(Factory :account)
        new_channel = Channel::Account.find_or_create_by_accounts account_array
        new_channel.should_not be_nil
      end

      # FIXME: Test dependent on nowmov account having tweeted videos.
      it "inserts videos into the channel of the given accounts" do
        accounts = Array(Account::Youtube.create :uid => "nowmov")
        channel = Channel::Account.find_or_create_by_accounts accounts, {},
          true
        channel.should_not be_nil
        channel.content_videos.should_not be_empty
      end
    end

    describe "#content_video_ids" do
      it "returns cached values when it can" do
        accounts = [(Factory :youtube_account_with_videos),
          (Factory :youtube_account_with_videos)]
        subject = Channel::Account.create :accounts=>accounts
        old_ids = subject.content_video_ids
        old_ids.should_not be_empty
        ea = Account::Youtube.create :uid => 'nowmov'
        subject.accounts << ea
        ea.refresh_content true
        ea.content_videos.should_not be_empty
        subject.content_video_ids.should == old_ids
      end
    end

    describe ".find_all_by_accounts" do
      before :each do
        @accounts = %w(machinima freddegredde).map{|n| Account::Youtube.create(
          :uid => n)}
      end

      context "when no channel exists" do
        it "returns an empty array" do
          Channel::Account.find_all_by_accounts(Array(@accounts)).should == []
        end
      end

      context "when channels are present" do
        it "returns all existing channels" do
          channel = Channel::Account.create :accounts => @accounts
          Channel::Account.find_all_by_accounts(Array(@accounts)).
            should == [channel]
        end
      end
    end
  end
end
