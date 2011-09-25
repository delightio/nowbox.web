require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Channel::Account do
    subject { Channel::Account.create accounts: @accounts }
    before(:each) do
      @accounts = %w{nowbox cnn }.map do |uid| Account::Youtube.create(
        :uid => uid)
      end
    end

    it_behaves_like "any content holder"
    describe "#refresh_content" do
      it "skips blacklisted accounts" do
        bad_author = Factory :youtube_account

        channel = Channel::Account.create accounts: (@accounts << bad_author)
        bad_author.should_receive(:blacklisted?).and_return(true)
        bad_author.should_not_receive(:refresh_content)
        channel.refresh_content
      end
    end

    it "should set title based on accounts" do
      subject.title.should == "nowbox, cnn"
    end

    describe "#serializable_hash" do
      it "returns an hash of account types" do
        youtube = Factory :youtube_channel
        youtube.serializable_hash['type'].should == "Account::Youtube"
        twitter = Factory :twitter_channel
        twitter.serializable_hash['type'].should == "Account::Twitter"
      end
    end

    # TODO: Refactor using context block to show Thomas
    describe ".find_or_create_by_accounts" do
      it "returns a new channel when there is no exact match" do
        new = Channel::Account.find_or_create_by_accounts @accounts[1..-1]
        new.class.should == Channel::Account
        new.should_not == subject
      end

      context "when a channel with those accounts exists" do
        it "returns the same channel even when accounts are disordered" do
          Channel::Account.find_or_create_by_accounts(
            subject.accounts).should == subject
          Channel::Account.find_or_create_by_accounts(
            subject.accounts.shuffle).should == subject
        end
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
          :refresh
        new_channel.should be_populated
      end

      it "passes initial parameters to .create" do
        test_title = random_string
        h = {:default_listing => true}
        ch = Channel::Account.find_or_create_by_accounts(@accounts, h)
        ch.default_listing.should == true
      end

      it "works with account which never has a channel on our system" do
        account_array = Array(Factory :account)
        new_channel = Channel::Account.find_or_create_by_accounts account_array
        new_channel.should_not be_nil
      end

      # FIXME: Test dependent on nowbox account having tweeted videos.
      it "inserts videos into the channel of the given accounts" do
        accounts = Array(Account::Youtube.create :uid => "nicnicolecole")
        channel = Channel::Account.find_or_create_by_accounts accounts, {},
          :reload
        channel.should_not be_nil
        channel.content_videos.should_not be_empty
      end
    end

    describe "#content_video_ids" do
      it "returns the union of all accounts' content_video_ids" do
        channel = Factory :youtube_channel
        ids = []
        channel.accounts.each { |a| ids += a.content_video_ids }
        Set.new(ids).should == Set.new(channel.content_video_ids)
      end

      it "returns cached values when it can" do
        channel = Factory :youtube_channel
        cached_ids = channel.content_video_ids
        channel.accounts << (Factory :youtube_account_with_videos)
        channel.save
        channel.content_video_ids.should == cached_ids
      end
    end

    describe ".find_all_by_accounts" do
      context "when no channel exists" do
        it "returns an empty array" do
          accounts = %w(machinima freddegredde).map{|n| Account::Youtube.create(
            :uid => n)}
          Channel::Account.find_all_by_accounts(accounts).should == []
        end
      end

      context "when channels are present" do
        it "returns all existing channels" do
          Channel::Account.find_all_by_accounts(subject.accounts).
            should == [subject]
          Channel::Account.find_all_by_accounts(subject.accounts.shuffle).
            should == [subject]
        end
      end
    end

    describe "#update_relevance_in_categories" do
      it "updates category relevance after #refresh_content" do
        subject.should_receive(:update_relevance_in_categories).
          with(an_instance_of(Array))
        subject.refresh_content
      end
      it "orders categories according to occurance in videos" do
        category1 = Factory :category
        video = Factory :populated_video, :category => category1
        expect {subject.update_relevance_in_categories [video] }.
          to change { subject.categories.first }.to category1

        # same category differnet video
        video = Factory :populated_video, :category => category1
        expect {subject.update_relevance_in_categories [video] }.
          to_not change { subject.categories.count }

        # 1 video in different category. 
        # top category is still category1 since it was from 2 videos
        category2 = Factory :category
        video = Factory :populated_video, :category => category2
        expect {subject.update_relevance_in_categories [video] }.
          to change { subject.categories.count }.by 1
        subject.categories.should == [category1, category2]
      end
    end

  end
end
