require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Channels::YoutubeAccount do
  describe "#populate" do
    it "fetches videos from youtube" do
      youtube_username = "nicnicolecole"
      nicole = Aji::ExternalAccounts::Youtube.create :provider => "youtube",
                                                     :uid => youtube_username
      yc = Aji::Channels::YoutubeAccount.create(:accounts => Array(nicole),
                                                :title => "#{youtube_username}'s channel")
      yc.populate
      h = JSON.parse yc.content_videos.first.to_json
      h["video"]["author"]["username"].should == youtube_username
    end

  end
end
