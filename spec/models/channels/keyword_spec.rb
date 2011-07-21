require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Channels::Keyword do
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
end

