require File.expand_path("../../spec_helper", __FILE__)

include Aji

describe Searcher, :net do

  before(:each) do
    Searcher.stub(:enabled?).and_return(true)
  end

  describe "#initialize" do
    let(:query) { random_string }

    it "strips out spaces" do
      query_with_spaces = "\t  #{query}  \r\n"
      searcher = Searcher.new query_with_spaces
      searcher.query.should == query
    end

    it "saves given query internally" do
      searcher = Searcher.new query
      searcher.query.should == query
    end

    it "removes any quotation within the query" do
      query_with_single_quote = " \' #{query}"
      searcher = Searcher.new query_with_single_quote
      searcher.query.should == query

      query_with_double_quote = " \" #{query}"
      searcher = Searcher.new query_with_double_quote
      searcher.query.should == query

    end
  end

  describe "#authors_from_channel_search" do
    let(:uids) { [stub, stub] }
    let(:accounts) { [stub, stub] }
    let(:query) { "blah" }
    subject { Searcher.new query }

    it "creates Account object from channel_search" do
      YoutubeAPI.any_instance.should_receive(:channel_search).
        with(query).and_return(uids)
      uids.each_with_index do |uid, index|
        Account::Youtube.should_receive(:find_or_create_by_lower_uid).
          with(uid).and_return(accounts[index])
      end

      subject.authors_from_channel_search.should == accounts
    end
  end

  describe "#unique_and_sorted" do
    subject { Searcher.new "" }
    let(:author1) { mock "author 1", :available? => true, :username => "bar",
                    :subscriber_count => 10 }
    let(:author2) { mock "author 2", :available? => true, :username => "foo",
                    :subscriber_count => 100 }
    let(:author3) { mock "author 3", :available? => false, :username => "baz" }
    let(:authors) {[author1, author1, author2, author3 ]}

    it "sorts the input and return unique and availabe results" do
      subject.unique_and_sorted(authors).should == [author2, author1]
    end

    it "removes authors with nil usernames" do
      authors << mock("empty author", :username => nil)

      subject.unique_and_sorted(authors).should == [author2, author1]
    end
  end

  describe "#results" do
    subject { @searcher }
    before do
      @account_count = 2
      @searcher = Searcher.new random_string
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
      @sorted_accounts = @accounts.sort do |x,y|
        y.subscriber_count <=> x.subscriber_count
      end
      @sorted_channels = @sorted_accounts.map &:to_channel
    end

    it "returns right the way when query is empty" do
      subject = Searcher.new " "
      subject.should_not_receive :account_results

      subject.results.should be_empty
    end

    context "multiple results are found" do
      before :each do
        subject.should_receive(:authors_from_channel_search).
          and_return(@accounts)
        subject.should_receive(:unique_and_sorted).
          with(@accounts).and_return(@sorted_accounts)
      end

      it "enqueue all channels for refresh" do
        @sorted_channels.each do |ch|
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

