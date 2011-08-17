require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Channel::Account do
    subject { Channel::Account.create :accounts =>  @accounts }
    before(:each) do
      @accounts = %w{nowmov cnn freddiew}.map do |uid| Account::Youtube.create(
        :uid => uid)
      end
    end

    it_behaves_like "any content holder"

    it "should set title based on accounts" do
      subject.title.should == "nowmov, cnn, freddiew"
    end

    # TODO: Refactor using context block to show Thomas
    describe ".find_or_create_by_accounts" do
      it "returns a new channel when there is no exact match" do
        new_channel = Channel::Account.find_or_create_by_accounts @accounts[1..-1]
        new_channel.class.should == Channel::Account
        new_channel.should_not == subject
      end

      it "returns same channel when we find an existing channel with given usernames" do
        found_channel = Channel::Account.find_or_create_by_accounts @accounts
        found_channel.should == subject
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

      # FIXME: Test dependent on nowmov account having tweeted videos.
      it "inserts videos into the channel of the given accounts" do
        accounts = Array(Account::Youtube.create :uid => "nicnicolecole")
        channel = Channel::Account.find_or_create_by_accounts accounts, {},
          :reload
        channel.should_not be_nil
        channel.content_videos.should_not be_empty
      end
    end

    describe "#content_video_ids" do
      # TODO: This test is smelly.
      it "returns cached values when it can" do
        subject.refresh_content
        old_ids = subject.content_video_ids
        old_ids.should_not be_empty
        a = Account::Youtube.create :uid => 'nicnicolecole'
        subject.accounts << a
        a.refresh_content :force
        a.content_videos.should_not be_empty
        subject.content_video_ids.should == old_ids
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
          @accounts.each do |a| puts (a.save || a.errors).inspect end
          puts subject.accounts.inspect
          Channel::Account.find_all_by_accounts(@accounts).
            should == [subject]
        end
      end
    end
  end
end
