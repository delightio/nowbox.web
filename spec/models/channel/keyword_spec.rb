require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Channel::Keyword do
  describe "#create" do
    before(:each) do
      @keywords = %w[ a b c d e f ]
    end
    subject { Aji::Channel::Keyword.create :keywords => @keywords.shuffle }
    it "sorts keywords before saving" do
      subject.keywords == @keywords
    end
    it "auto enqueues refresh channel" do
      Resque.should_receive(:enqueue).with(
        Aji::Queues::RefreshChannel, subject.id ).once
    end
  end

  describe "#refresh_content" do
    it "fetches videos from youtube and becomes populated" do
      uke = Aji::Channel::Keyword.create(:keywords => %w[ukulele],
                                :title => "ukukele channel")
      uke.content_videos.should be_empty
      uke.refresh_content
      uke.content_videos.should_not be_empty
      uke.should be_populated
    end
  end

  it "should set title based on keywords if no title is given" do
    keywords = %w[ukulele nowmov]
    ch = Aji::Channel::Keyword.create :keywords => keywords
    ch.title.should == Aji::Channel::Keyword.to_title(keywords)
  end

  describe "#search_helper" do
    before(:each) do
      @count = 3
      @query = Array.new(@count){ |n| random_string }.join(",")
    end

    it "does not create new channel" do
      expect { Aji::Channel::Keyword.search_helper @query }.
        to_not change { Aji::Channel.count }
    end

    it "returns a match even if partial match is shorter" do
      q = @query.split(',').shuffle.sample(@count-1)
      old_keyword_channel = Aji::Channel::Keyword.create(
        :keywords => q)
      results = Aji::Channel::Keyword.search_helper @query
      results.should have(1).channel
      results.should include old_keyword_channel
    end

    it "returns a match even if partial match is longer" do
      q = @query.split(',').shuffle << random_string
      old_keyword_channel = Aji::Channel::Keyword.create(
        :keywords => q)
      results = Aji::Channel::Keyword.search_helper @query
      results.should have(1).channel
      results.should include old_keyword_channel
    end

    it "returns existing keyword channel if previously existed regardless of query order" do
      old_keyword_channel = Aji::Channel::Keyword.create(
        :keywords => @query.split(',').shuffle)
      results = Aji::Channel::Keyword.search_helper @query
      results.should have(1).channel
      results.should include old_keyword_channel
    end
  end
end

