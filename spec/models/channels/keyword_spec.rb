require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Channels::Keyword do
  describe "#create" do
    it "sorts keywords before saving" do
      keywords = %w[ a b c d e f ]
      c = Aji::Channels::Keyword.create :keywords => keywords.shuffle
      Aji::Channels::Keyword.find(c.id).keywords.should == keywords
    end
  end
  
  describe "#populate" do
    it "fetches videos from youtube and become populated" do
      uke = Aji::Channels::Keyword.create(:keywords => %w[ukulele],
                                :title => "ukukele channel")
      uke.save
      uke.content_videos.should be_empty
      uke.populate
      uke.content_videos.should_not be_empty
      Aji::Channel.find(uke.id).should be_populated
    end
  end

  it "should set title based on keywords if no title is given" do
    keywords = %w[ukulele nowmov]
    ch = Aji::Channels::Keyword.create :keywords => keywords
    ch.title.should == Aji::Channels::Keyword.to_title(keywords)
  end
  
  describe "#search_helper" do
    before(:each) do
      @query = Array.new(3){ |n| random_string }.join(",")
    end
    
    it "returns at least one populated keyword channel" do
      results = Aji::Channels::Keyword.search_helper @query
      results.map(&:class).should include Aji::Channels::Keyword
    end
    
    it "returns existing keyword channel if previously existed regardless of query order" do
      old_keyword_channel = Aji::Channels::Keyword.create(
        :keywords => @query.split(',').shuffle)
      results = Aji::Channels::Keyword.search_helper @query
      results.should have(1).channel
      results.should include old_keyword_channel
    end
  end
end

