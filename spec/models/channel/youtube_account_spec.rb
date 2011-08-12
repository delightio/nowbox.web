require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Channel::Account do
    before(:each) do
      @usernames = []
      3.times { |n| @usernames << (Factory :account).uid }
    end
    subject { Channel::Account.find_or_create_by_usernames @usernames }

    it "should set title based on accounts if no title is given" do
      subject.title.should == Channel::Account.to_title(subject.accounts)
    end

    describe "#refresh_content" do
      it "fetches videos from youtube" do
        youtube_username = "nicnicolecole"
        yc = Channel::Account.find_or_create_by_usernames [youtube_username]
        expect { yc.refresh_content }.to change(yc, :content_video_ids).from([])

        ## @tpun What is this?????
        #h = JSON.parse yc.content_videos.first.to_json
        #h["video"]["author"]["username"].should == youtube_username
      end

      it "does not refresh within short time" do
        real_youtube_users = ["nowmov", "cnn", "freddiew"]
        subject = Channel::Account.find_or_create_by_usernames real_youtube_users
        subject.should_receive(:save).once
        subject.refresh_content
        subject.should_not_receive(:save)
        subject.refresh_content
      end

      it "allows forced refresh" do
        real_youtube_users = ["nowmov", "cnn", "freddiew"]
        subject = Channel::Account.find_or_create_by_usernames real_youtube_users
        subject.refresh_content
        subject.accounts.each { |a| a.should_receive(:refresh_content).once }
        subject.refresh_content true
      end

      it "waits for the lock before populating"
    end

    describe ".find_or_create_by_usernames" do

      it "returns a new channel when there is no exact match" do
        subject = Channel::Account.find_or_create_by_usernames @usernames
        subject.should_not be_nil
        @usernames.delete @usernames.sample
        new_channel = Channel::Account.find_or_create_by_usernames @usernames
        new_channel.should_not == subject
      end

      it "returns same channel when we find an existing channel with given usernames" do
        new_channel = Channel::Account.find_or_create_by_usernames @usernames
        old_channel = Channel::Account.find_or_create_by_usernames @usernames
        new_channel.should == old_channel
      end

      it "returns a channel with given youtube usernames" do
        subject.accounts.map(&:uid).should == @usernames
      end

      it "returns un-populated channel by default" do
        subject.should_not be_populated
      end

      it "populates new channel when asked" do
        @usernames.delete @usernames.sample
        new_channel = Channel::Account.find_or_create_by_usernames @usernames,
          :populate_if_new => true
        Channel.find(new_channel.id).should be_populated
      end

      it "returns a channel with given title" do
        test_title = random_string
        @usernames.delete @usernames.sample
        new_channel = Channel::Account.find_or_create_by_usernames @usernames,
          :title => test_title
        Channel.find(new_channel.id).title.should == test_title
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
        usernames = [ random_string ]
        new_channel = Channel::Account.find_or_create_by_usernames usernames
        new_channel.should_not be_nil
      end

      it "insert the videos into the channel of the given accounts" do
        usernames = [ "nowmov" ]
        (Account::Youtube.find_by_uid "nowmov").should be_nil
        new_channel = Channel::Account.find_or_create_by_usernames usernames,
          :populate_if_new => true
        new_channel.should_not be_nil
        nowmov = Account::Youtube.find_by_uid "nowmov"
        nowmov.should_not be_nil
        channel = nowmov.channels.first
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


    describe ".find_by_accounts" do
      it "returns nil when no accounts given"
      it "returns nil when there is no exact match"
      it "returns a channel for a single account"
      it "returns a channel for two accounts with an existing channel"
      it "returns a channel for multiple accounts with an existing channel"
    end
  end
end
