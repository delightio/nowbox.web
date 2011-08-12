require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Channel::Account do
    before(:each) do
      @accounts = (0..2).map { Factory :account }
    end

    subject { Channel::Account.find_or_create_by_accounts @accounts }

    it "should set title based on accounts if no title is given" do
      subject.title.should match /(?:{.*}'s) Videos/
    end

    describe "#refresh_content" do
      it "fetches videos from youtube" do
        youtube_account = Account::Youtube.create :uid => "nicnicolecole"
        c = Channel::Account.find_or_create_by_accounts [youtube_account]
        expect { c.refresh_content }.to change(c, :content_video_ids).from([])
      end

      it "does not refresh within short time" do
        real_youtube_users = ["nowmov", "cnn", "freddiew"].map do |uid|
          Account::Youtube.create :uid => uid
        end

        subject = Channel::Account.find_or_create_by_accounts real_youtube_users
        subject.refresh_content
        subject.should_not_receive(:save)
        subject.refresh_content
      end

      it "allows forced refresh" do
        real_youtube_users = ["nowmov", "cnn", "freddiew"].map do |uid|
          Account::Youtube.create :uid => uid
        end

        subject = Channel::Account.find_or_create_by_accounts real_youtube_users
        subject.refresh_content
        subject.accounts.each { |a| a.should_receive(:refresh_content).once }
        subject.refresh_content true
      end

      it "waits for the lock before populating"
    end

    # TODO: Refactor using context block to show Thomas
    describe ".find_or_create_by_accounts" do

      it "returns a new channel when there is no exact match" do
        subject = Channel::Account.find_or_create_by_accounts @accounts
        subject.should_not be_nil
        @accounts.delete @accounts.sample
        new_channel = Channel::Account.find_or_create_by_accounts @accounts
        new_channel.should_not == subject
      end

      it "returns same channel when we find an existing channel with given usernames" do
        new_channel = Channel::Account.find_or_create_by_accounts @accounts
        old_channel = Channel::Account.find_or_create_by_accounts @accounts
        new_channel.should == old_channel
      end

      it "returns a channel with given youtube accounts" do
        subject.accounts.should == @accounts
      end

      it "returns unpopulated channel by default" do
        subject.should_not be_populated
      end

      it "populates new channel when asked" do
        @accounts.delete @accounts.sample
        new_channel = Channel::Account.find_or_create_by_accounts @accounts, {},
          true
        new_channel.should be_populated
      end

      it "passes initial parameters to .create" do
        test_title = random_string
        test_category = Aji::Supported.categories.sample
        h = {:title => test_title, :category => test_category, :default_listing => true}
        ch = Channel::Account.find_or_create_by_usernames(@usernames, h)
        Channel.find(ch.id).title.should == test_title
        Channel.find(ch.id).category.should == test_category
        Channel.find(ch.id).default_listing.should == true
      end

      it "works with account which never has a channel on our system" do
        account_array = Array(Factory :account)
        new_channel = Channel::Account.find_or_create_by_accounts account_array
        new_channel.should_not be_nil
      end

      # FIXME: Test dependent on nowmov account having tweeted videos.
      it "inserts videos into the channel of the given accounts" do
        Account::Youtube.find_by_uid("nomwov").delete
        accounts = Array(Account::Youtube.create :uid => "nowmov")
        new_channel = Channel::Account.find_or_create_by_accounts accounts, {},
          true
        new_channel.should_not be_nil
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
  end
end
