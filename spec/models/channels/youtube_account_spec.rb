require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Channels::YoutubeAccount do
  describe "#populate" do
    it "fetches videos from youtube" do
      author = Aji::ExternalAccount::Youtube.new :provider => "youtube",
        :uid => "nicnicolecole"
      author.save

      ac = Aji::Channels::YoutubeAccount.new(:authors => Array(author),
                                :title => "nicnicolecole's channel")
      ac.save
      ac.content_videos.should be_empty
      ac.populate
      ac.content_videos.should_not be_empty
    end

  end
end
