require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Channel::Account, :net do
   # before :all do
     # VCR.config do |c|
     #   c.cassette_library_dir = "spec/cassettes"
     #   c.stub_with :typhoeus
     #   c.default_cassette_options = { :record => :all }
     # end
   # end

    subject { Channel::Account.create accounts: accounts }

    let(:accounts) do
      %w[freddiew brentalfloss].map { |uid| Account::Youtube.create uid:uid }
    end

    it_behaves_like "any channel"

    describe "#refresh_content" do
      it "skips blacklisted accounts" do
        bad_author = Account.new uid: "badman"
        channel = Channel::Account.create accounts: (accounts + [bad_author])
        bad_author.should_receive(:blacklisted?).and_return(true)
        bad_author.should_not_receive(:refresh_content)
        accounts.each {|a| a.should_receive(:refresh_content).and_return([])}
        channel.refresh_content
      end

      it "updates category relevance after" do
        subject.accounts.each {|a| a.should_receive(:refresh_content).and_return([mock])}
        subject.should_receive(:update_relevance_in_categories)
        subject.refresh_content
      end
    end

    describe "#most_significant_account" do
      it "returns account with most subscribers" do
        account1 = mock "account", :subscriber_count => 10
        account2 = mock "account", :subscriber_count => 20
        most_significant = mock "account", :subscriber_count => 10000
        subject.stub(:accounts).and_return([account1, account2, most_significant].shuffle)
        subject.most_significant_account.should == most_significant
      end
    end

    describe "#subscriber_count" do
      it "returns the max number of subscribers among all the accounts" do
        subject.stub(:most_significant_account).and_return(mock("account", :subscriber_count=>12))
        subject.subscriber_count.should == 12
      end
    end

    it "should set title based on accounts" do
      subject.title.should == "freddiew, brentalfloss"
    end

    describe "#serializable_hash" do
      it "returns an hash of account types" do

        channel = Channel::Account.new
        # TODO: Too bad we can't stub super
        channel.stub(:category_ids).and_return([])
        channel.stub(:subscriber_count).and_return(0)
        channel.stub(:content_video_id_count).and_return(0)
        channel.stub(:accounts).and_return([Account::Youtube.new])
        channel.serializable_hash['type'].should == "Account::Youtube"

        channel.stub(:accounts).and_return([Account::Twitter.new])
        channel.serializable_hash['type'].should == "Account::Twitter"
      end
    end

    describe ".find_or_create_by_accounts" do
      it "returns a new channel when there is no exact match" do
        new = Channel::Account.find_or_create_by_accounts accounts[1..-1]
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
        subject.accounts.should == accounts
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
        ch = Channel::Account.find_or_create_by_accounts(accounts, h)
        ch.default_listing.should == true
      end

      it "works with account which never has a channel on our system" do
        account = Account.new
        account.save :validate=>false
        new_channel = Channel::Account.find_or_create_by_accounts([account])
        new_channel.should_not be_nil
      end

      # FIXME: Test dependent on nowbox account having tweeted videos.
      it "inserts videos into the channel of the given accounts" do
        # account = Account.new
        # account.save :validate=>false
        # account.should_receive(:refresh_content).and_return([mock.as_null_object])
        # Channel.any_instance.should_receive(:update_relevance_in_categories)
        # channel = Channel::Account.find_or_create_by_accounts [account], {},
        accounts = Array(Account::Youtube.create :uid => "nicnicolecole")
        channel = Channel::Account.find_or_create_by_accounts accounts, {},
          :reload
        channel.should_not be_nil
        channel.content_videos.should_not be_empty
      end
    end

    describe "#content_video_ids" do
      before :each do
        accounts = []
        videos = [mock("video",:id=>1), mock("video",:id=>2), mock("video",:id=>3)]
        3.times do |n|
          account = Account.new
          account.save :validate=>false
          account.push videos[n]
          accounts << account
        end
        subject = Channel::Account.create accounts: accounts.first(2)
      end

      it "returns the union of all accounts' content_video_ids" do
        subject.content_video_ids == [1,2]
      end

      it "returns cached values when it can" do
        cached_ids = subject.content_video_ids
        subject.accounts << (accounts.last)
        subject.save
        subject.content_video_ids.should == cached_ids
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

    describe "#relevance" do
      subject { Channel::Account.new }
      it "defaults to 1000" do
        subject.stub(:subscriber_count).and_return(0)
        subject.relevance.should == 100
      end

      it "doubles when you hit 100k subscribers" do
        subject.stub(:subscriber_count).and_return(10000)
        subject.relevance.should == 100*2
      end
    end

    describe "#update_relevance_in_categories" do
      it "orders categories according the relevance of each channel" do
        category1 = mock "category1", :id=>1, :update_channel_relevance=>nil
        video1 = mock "video", :id=>1, :category=>category1

        channel1 = Channel::Account.new
        channel1.save :validate=>false
        channel1.stub(:relevance).and_return(100)
        channel1.stub(:content_videos).with(100).and_return([video1])
        category1.should_receive(:update_channel_relevance).
          with(channel1, channel1.relevance)

        expect { channel1.update_relevance_in_categories }.
          to change { channel1.category_ids.first }.
          from(nil).to(category1.id)

        category2 = mock "category2", :id=>2, :update_channel_relevance=>nil
        video2 = mock "video", :id=>2, :category=>category2
        video3 = mock "video", :id=>3, :category=>category2
        channel1.stub(:content_videos).with(100).and_return([video1, video2, video3])
        category1.should_receive(:update_channel_relevance).
          with(channel1, channel1.relevance * 1 / 3 )
        category2.should_receive(:update_channel_relevance).
          with(channel1, channel1.relevance * 2 / 3 ) # 2 videos w/ cat2

        expect { channel1.update_relevance_in_categories }.
          to change { channel1.category_ids }.
          from([category1.id]).to([category2.id, category1.id])

      end
    end

    describe "#background_refresh_content" do
      it "enques a refresh job" do
        Resque.should_receive(:enqueue).with(
          Aji::Queues::RefreshChannel, subject.id).at_most(2).times
        subject.background_refresh_content
      end
    end

  end
end
