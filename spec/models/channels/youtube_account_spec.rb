require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Channels::YoutubeAccount do
    describe "#populate" do
      it "fetches videos from youtube" do
        youtube_username = "nicnicolecole"
        nicole = ExternalAccounts::Youtube.create :uid => youtube_username
        yc = Channels::YoutubeAccount.create(:accounts => Array(nicole),
                                                  :title => "#{youtube_username}'s channel")
        yc.populate
        h = JSON.parse yc.content_videos.first.to_json
        h["video"]["author"]["username"].should == youtube_username
      end
    end
  
    describe ".find_or_create_by_usernames" do
      before(:each) do
        @usernames = []
        3.times { |n| @usernames << (Factory :external_account).uid }
      end
      subject { Channels::YoutubeAccount.find_or_create_by_usernames @usernames }
      
      it "returns a new channel when there is no exact match" do
        subject = Channels::YoutubeAccount.find_or_create_by_usernames @usernames
        subject.should_not be_nil
        @usernames.delete @usernames.sample
        new_channel = Channels::YoutubeAccount.find_or_create_by_usernames @usernames
        new_channel.should_not == subject
      end
      
      it "returns same channel when we find an existing channel with given usernames" do
        new_channel = Channels::YoutubeAccount.find_or_create_by_usernames @usernames
        old_channel = Channels::YoutubeAccount.find_or_create_by_usernames @usernames
        new_channel.should == old_channel
      end
      
      it "returns a channel with given youtube usernames" do
        subject.accounts.map(&:uid).should == @usernames
      end
      
      it "returns un-populated channel by default" do
        pending "no populated_at yet"
        subject.should_not be_populated
      end
      
      it "populates new channel when asked" do
        pending "no populated_at yet"
        @usernames.delete @usernames.sample
        new_channel = Channels::YoutubeAccount.find_or_create_by_usernames @usernames,
          :poulate_if_new => true
        new_channel.should be_populated
      end
      
      it "returns a channel with given title" do
        test_title = random_string
        @usernames.delete @usernames.sample
        new_channel = Channels::YoutubeAccount.find_or_create_by_usernames @usernames,
          :title => test_title
        Channel.find(new_channel.id).title.should == test_title
      end
    end
  
    describe ".find_by_accounts" do
      it "returns nil when no accounts given"
      it "returns nil when there is no exact match"
      it "returns a channel for a single account"
      it "returns a channel for two accounts with an existing channel"
      it "returns a channel for multiple accounts with an existing channel"
    end
  end
end