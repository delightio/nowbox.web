require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Channels::Author do
  describe "#populate" do
    it "fetches videos from youtube" do
      author = Aji::Author.new :screen_name => "nicnicolecole",
        :video_source => :youtube
      author.save

      ac = Channels::Author.new(:authors => Array.new(author),
                                :title => "nicnicolecole's channel")
      ac.content_videos.should be_empty
      ac.populate
      ac.content_videos.should_not be_empty
    end

  end
end
