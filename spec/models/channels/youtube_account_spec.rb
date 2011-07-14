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

    describe "#find_by_accounts" do
      it "returns nil when no accounts given"
      it "returns nil when no channels exist for a given account"
      it "returns nil when no channels exist for the given accounts"
      it "returns a channel for a single account"
      it "returns a channel for two accounts with an existing channel"
      it "returns a channel for multiple accounts with an existing channel"
    end
  end
end
