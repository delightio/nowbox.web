require File.expand_path("../../spec_helper", __FILE__)

module Aji

  describe Searcher do

    before(:each) do
      Searcher.stub(:enabled?).and_return(true)
    end

    describe "#account_results_from_indextank" do

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

    describe "#account_results" do
      it "creates YouTube channel if we don't have it in our db" do
        query = random_string
        subject = Searcher.new query

        youtube_account = mock "youtube"
        Account::Youtube.should_receive(:create_if_existing).
          with(query).and_return(youtube_account)

        subject.stub(:account_results_from_indextank).and_return([])
        subject.account_results.should == [youtube_account]
      end

      it "will not search youtube for existing accounts if query has more than 1 word" do
        query = "steve jobs"
        subject = Searcher.new query

        subject.stub(:account_results_from_indextank).and_return([])
        Account::Youtube.should_receive(:create_if_existing).never

        subject.account_results
      end

    end

    describe "#video_results_from_keywords" do
      let(:query) { "blah" }
      subject { Searcher.new query }

      it "does a search on given query as keyword search on YouTube" do
        YoutubeAPI.any_instance.should_receive(:keyword_search).
          with(query, Searcher.max_video_count_from_keyword_search)
        subject.video_results_from_keywords
      end
    end

    describe "#channel_results" do
      let(:channel1) { mock "channel 1" }
      let(:channel2) { mock "channel 2"}
      let(:author_1) { mock "author 1", :to_channel => channel1 }
      let(:author_2) { mock "author 2", :to_channel => channel2 }
      let(:keyword_search_results) {
        Array.new(3, mock("video 1", :author => author_1)) +
        Array.new(3, mock("video 2", :author => author_2))
      }
      subject { Searcher.new "" }

      it "creates channels from the unique authors out of the search results" do
        subject.should_receive(:video_results_from_keywords).
          and_return(keyword_search_results)
        subject.channel_results.should == ([channel1, channel2])
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
              :background_refresh_content => nil,
              :available? => true)
            channels << channel
          end
        end
        @accounts = [].tap do |accounts|
          @account_count.times do |n|
            account = mock("account", :id => n,
              :username => random_string,
              :to_channel => @channels[n],
              :subscriber_count => n*1000)
            # TODO this sucks
            @channels[n].stub(:accounts).and_return([account])
            accounts << account
          end
        end
        @sorted_channels = @channels.sort do |x,y|
          y.accounts.first.subscriber_count <=> x.accounts.first.subscriber_count
        end
        @searcher.stub(:account_results).and_return(@accounts)
      end

      context "multiple results are found" do
        it "returns unique results" do
          subject.stub(:account_results).and_return(
            @accounts)
          subject.stub(:channel_results).and_return(
            @accounts.map(&:to_channel))
          results = subject.results
          results.should have(@account_count).channels
          results.should == @sorted_channels
        end

        it "enqueue all channels for refresh" do
          @channels.each do |ch|
            ch.should_receive(:background_refresh_content).once
          end
          subject.results
        end

        it "sorts channels by subscriber count" do
          subject.should_receive(:account_results).
            and_return []
          subject.should_receive(:channel_results).
            and_return @channels
          subject.results.should == @sorted_channels
        end

      end

      it "allows NowPopular channel to be searched" do
        query = 'now popular'
        subject = Searcher.new query

        subject.stub(:account_results).and_return([])
        Account::Youtube.stub(:create_if_existing).and_return(nil)

        subject.results.should include Channel.trending
      end

    end

    context "when #results contains blacklisted channel" do
      it "does not return blacklisted channels" do
        blacklisted_channel = mock "bad channel", :available? => false
        blacklisted_account = mock "spammer",
          :username => "spammer", :to_channel => blacklisted_channel
        blacklisted_channel.stub(:accounts).and_return([blacklisted_account])
        blacklisted_channel.should_not_receive(:background_refresh_content)

        subject = Searcher.new random_string
        subject.stub(:account_results).and_return([blacklisted_account])
        subject.results.should_not include blacklisted_channel
      end
    end

  end
end