require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Channels::Trending do
  describe "#populate" do
    it "fetches some videos from nowmov.com" do
      n = 5
      trending = Aji::Channels::Trending.create :title => "Trending channel from spec test"
      trending.content_videos.should be_empty
      Aji::Video.count.should == 0
      trending.populate :limit=>n
      Aji::Video.count.should > 0
      trending.content_videos.count.should == Aji::Video.count
    end

  end
end

