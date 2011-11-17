require File.expand_path("../../spec_helper", __FILE__)

include Aji

describe Searcher, :net do

  before(:each) do
    Searcher.stub(:enabled?).and_return(true)
  end

  describe "#initialize" do
    it "strips out spaces" do
      query = random_string
      query_with_spaces = "\t  #{query}  \r\n"
      searcher = Searcher.new query_with_spaces
      searcher.query.should == query
    end
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

  describe "#authors_from_keyword_search" do
    subject { Searcher.new "" }
    it "returns authors from keyword search result" do
      author = mock "author"
      video = mock "video", :author => author
      videos = [video]
      subject.should_receive(:video_results_from_keywords).
        and_return(videos)
      subject.authors_from_keyword_search.should == [author]
    end
  end

  describe "#unique_and_sorted" do
    let(:author1) { mock "author 1", :available? => true,
                    :subscriber_count => 10 }
    let(:author2) { mock "author 2", :available? => true,
                    :subscriber_count => 100 }
    let(:author3) { mock "author 3", :available? => false}
    let(:authors) {[author1, author1, author2, author3 ]}

    it "sorts the input and return unique and availabe results" do
      Searcher.new("").unique_and_sorted(authors).should == [author2, author1]
    end
  end

  describe "#results" do
    subject { @searcher }
    before do
      @account_count = 2
      @searcher = Searcher.new ""
      @accounts = (1..@account_count).map do |n|
        account = mock("account", :id => n,
                       :username => random_string,
                       :available? => true,
                       :subscriber_count => n*1000)
        account.stub(
          :to_channel => mock("channel",
                              :background_refresh_content => [],
                              :accounts => [account]))
                              account
      end
      @channels = @accounts.map &:to_channel

      @sorted_channels = @channels.sort do |x,y|
        y.accounts.first.subscriber_count <=> x.accounts.first.subscriber_count
      end
      @searcher.stub(:account_results).and_return(@accounts)
    end

    context "multiple results are found" do
      before :each do
        subject.stub(:account_results).and_return(@accounts)
        subject.stub(:authors_from_keyword_search).and_return(@accounts)
      end

      it "returns unique results" do
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
        subject.results.should == @sorted_channels
      end

    end

    xit "allows NowPopular channel to be searched" do
      query = 'now popular'
      subject = Searcher.new query

      subject.stub(:account_results).and_return([])
      subject.stub(:authors_from_keyword_search).and_return([])

      subject.results.should include Channel.trending
    end
  end
end

