require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Channels::YoutubeAccount do
  describe "#populate" do
    it "fetches videos from youtube" do
      nicole = Aji::ExternalAccount::Youtube.new :provider => "youtube",
        :uid => "nicnicolecole"
      nicole.save

      yc = Aji::Channels::YoutubeAccount.new(:authors => Array(author),
                                :title => "nicnicolecole's channel")
      yc.save
      yc.content_videos.should be_empty
      yc.populate
      yc.content_videos.should_not be_empty
    end

  end
end
