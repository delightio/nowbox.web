require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Channels::Keyword do
  describe "#populate" do
    it "fetches videos from youtube" do
      uke = Aji::Channels::Keyword.new(:keywords => %w[ukulele],
                                :title => "ukukele channel")
      uke.save
      uke.content_videos.should be_empty
      uke.populate
      uke.content_videos.should_not be_empty
    end

  end
end

