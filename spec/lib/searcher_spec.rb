require File.expand_path("../../spec_helper", __FILE__)

module Aji

  describe Searcher do

    before(:each) do
      Searcher.stub(:enabled?).and_return(true)
    end

    describe "#account_results" do

      context "when searching for existing account" do
        subject { Searcher.new @query }
        before :each do
          @query = "nowmov"
          @account = Account::Twitter.new(:uid => "355199843",
            :username => @query)
          @account.stub(:searchable?).and_return(true)
          @account.save
        end

        it "returns result from IndexTank" do
          subject.account_results.should include @account
        end
      end
    end

    describe "#results" do
      subject { @searcher }
      before do
        @account_count = 2
        @searcher = Searcher.new ""
        @channels = [].tap do |channels|
          @account_count.times do |n|
            channel = mock("channel", :id => n,
              :background_refresh_content => nil)
            channels << channel
          end
        end
        @accounts = [].tap do |accounts|
          @account_count.times do |n|
            account = mock("account", :id => n,
              :username => random_string,
              :blacklisted? => false,
              :to_channel => @channels[n])
            # TODO this sucks
            @channels[n].stub(:accounts).and_return([account])
            accounts << account
          end
        end
        @searcher.stub(:account_results).and_return(@accounts)
      end

      context "multiple results are found" do
        it "returns unique results" do
          subject.stub(:account_results).and_return(
            @accounts << @accounts.first)
          results = subject.results
          results.should have(@account_count).channels
          results.should == @channels
        end

        it "enqueue all channels for refresh" do
          @channels.each do |ch|
            ch.should_receive(:background_refresh_content).once
          end
          subject.results
        end
      end

      it "creates YouTube channel if we don't have it in our db" do
        query = random_string
        subject = Searcher.new query

        youtube_account = @accounts.first
        Account::Youtube.should_receive(:create_if_existing).
          with(query).and_return(youtube_account)

        subject.stub(:account_results).and_return([])
        subject.results.should == [youtube_account.to_channel]
      end

      it "allows NowPopular channel to be searched" do
        query = 'now popular'
        subject = Searcher.new query

        subject.stub(:account_results).and_return([])
        Account::Youtube.stub(:create_if_existing).and_return(nil)

        subject.results.should include Channel.trending
      end

      it "will not search youtube for existing accounts if query has more than 1 word" do
        query = "steve jobs"
        subject = Searcher.new query

        subject.stub(:account_results).and_return([])
        Account::Youtube.should_receive(:create_if_existing).never

        subject.results
      end

    end

    context "when #results contains blacklisted channel" do
      it "does not return blacklisted channels" do
        blacklisted_channel = mock "channel with blacklisted account"
        blacklisted_account = mock "spammer",
          :blacklisted? => true, :username => "spammer",
          :to_channel => blacklisted_channel
        blacklisted_channel.stub(:accounts).and_return([blacklisted_account])
        blacklisted_channel.should_not_receive(:background_refresh_content)

        subject = Searcher.new random_string
        subject.stub(:account_results).and_return([blacklisted_account])
        subject.results.should_not include blacklisted_channel
      end
    end

  end
end