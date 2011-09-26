require File.expand_path("../../spec_helper", __FILE__)

module Aji

  describe Searcher do

    before(:each) do
      Searcher.stub(:enabled?).and_return(true)
    end

    describe "#channel_results" do

      context "when searching for query" do
        subject { Searcher.new @query }
        before :each do
          @query = "nowmov"
          @accounts = [(Account::Youtube.create uid: @query)]
          @account_channel = Channel::Account.create accounts: @accounts
          @keyword_channel = Channel::Keyword.create keywords: [@query]
        end

        it "returns results from IndexTank" do
          result = subject.channel_results
          result.should include @account_channel
          result.should include @keyword_channel
        end
      end

      context "when searching for what's popular" do
        subject { Searcher.new "popular" }
        before :each do
          @trending_channel = Channel.trending
        end

        it "returns trending channel when searching for popular" do
          subject.channel_results.should include @trending_channel
        end
      end
    end

    describe "#account_results" do
      
      context "when searching for existing account" do
        subject { Searcher.new @query }
        before :each do
          @query = "nowmov"
          @account = Account::Twitter.create(:uid => "355199843",
            :username => @query)
        end

        it "returns result from IndexTank" do
          subject.account_results.should include @account
        end
      end
    end

    describe "#results" do
      subject { @searcher }
      before do
        @searcher = Searcher.new ""
        @channel = mock("channel", :id=>1)
        @account = mock("account", :id=>1)
        @account.stub(:to_channel).and_return(@channel)
        @account.stub(:username).and_return(random_string)
        @searcher.stub(:account_results).and_return([@account])
        @searcher.stub(:channel_results).and_return([@channel])
      end

      context "multiple results are found" do
        it "returns unique results" do
          results = subject.results
          results.should have(1).channel
          results.should include @channel
        end
      end

      it "enqueue all channels for refresh" do
        Resque.should_receive(:enqueue).with(Queues::RefreshChannel, @channel.id)
        subject.results
      end

      it "creates YouTube channel if we don't have it in our db" do
        subject = Searcher.new "nowmov"
        subject.stub(:account_results).and_return([])
        subject.stub(:channel_results).and_return([])
        results = subject.results
        results.should have(1).channel
        results.first.accounts.first.uid.should == "nowmov"
      end

    end

  end
end