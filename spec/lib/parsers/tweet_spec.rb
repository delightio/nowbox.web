require File.expand_path("../../../spec_helper", __FILE__)

# TODO: These tests aren't very dry I wonder if there's a way to use RSpec's
# `behaves_like` functionality. Or perhaps just metaprogram these.
describe Aji::Parsers::Tweet do
  before :each do
    @valid_json = %q`{"coordinates":null,"in_reply_to_user_id":null,"retweet_count":0,"in_reply_to_status_id":null,"id_str":"99173522345181187","created_at":"Thu Aug 04 17:43:04 +0000 2011","user":{"listed_count":3,"time_zone":"Pacific Time (US & Canada)","protected":false,"show_all_inline_media":false,"contributors_enabled":false,"following":true,"profile_use_background_image":true,"url":"http:\/\/www.nuclearsandwich.com","name":"Steven! Ragnar\u00f6k","profile_background_image_url_https":"https:\/\/si0.twimg.com\/profile_background_images\/152331896\/xbda2af1914056587d6c489cd4e0e9d7.png","profile_background_color":"36AB8A","id_str":"178492493","profile_background_image_url":"http:\/\/a0.twimg.com\/profile_background_images\/152331896\/xbda2af1914056587d6c489cd4e0e9d7.png","utc_offset":-28800,"created_at":"Sat Aug 14 22:45:59 +0000 2010","friends_count":267,"profile_image_url_https":"https:\/\/si0.twimg.com\/profile_images\/1432767260\/steven_nuclearsandwich.com_normal.png","description":"CS\/Math student, Linux user and FOSS enthusiast. Expect to see comp. sci. nuttery, math antics, and the odd post about games or books. Work: http:\/\/nowmov.com","default_profile_image":false,"notifications":false,"favourites_count":215,"profile_text_color":"3F4233","is_translator":false,"statuses_count":2029,"profile_sidebar_fill_color":"CAE62E","follow_request_sent":false,"lang":"en","geo_enabled":false,"profile_background_tile":true,"profile_image_url":"http:\/\/a3.twimg.com\/profile_images\/1432767260\/steven_nuclearsandwich.com_normal.png","default_profile":false,"verified":false,"profile_link_color":"8EB315","followers_count":95,"screen_name":"_nuclearsammich","id":178492493,"profile_sidebar_border_color":"FF5500","location":"Silicon Valley, CA"},"favorited":false,"in_reply_to_status_id_str":null,"entities":{"user_mentions":[],"hashtags":[{"indices":[31,37],"text":"rspec"},{"indices":[128,132],"text":"wtf"},{"indices":[133,138],"text":"ruby"}],"urls":[]},"place":null,"in_reply_to_screen_name":null,"source":"\u003Ca href=\"http:\/\/identi.ca\" rel=\"nofollow\"\u003Eidentica\u003C\/a\u003E","in_reply_to_user_id_str":null,"id":99173522345181187,"contributors":null,"geo":null,"retweeted":false,"truncated":false,"text":"Under what circumstances would #rspec show me a stacktrace from a test example without the formatter because that is happening. #wtf #ruby"}`

    @invalid_json = "sasquatch"
  end
  context "when passed valid json" do
    it "returns a mention object" do
      Aji::Parsers::Tweet.parse(@valid_json).class.should == Aji::Mention
    end

    context "when a block returning true is passed" do
      it "returns a mention object with uid" do
        m = Aji::Parsers::Tweet.parse @valid_json do |tweet|
          true
        end
        m.class.should == Aji::Mention
        m.uid.should_not be_nil
      end
    end

    context "when a block returning false is passed" do
      it "returns nil" do
        m = Aji::Parsers::Tweet.parse @valid_json do |tweet|
          false
        end
        m.should be_nil
      end
    end
  end

  context "when invalid json is passed" do
    it "returns nil" do
      Aji::Parsers::Tweet.parse(@invalid_json).should be_nil
    end
  end

  context "when passed a parsed json hash" do
    it "returns a mention object" do
      Aji::Parsers::Tweet.parse(MultiJson.decode(@valid_json)).class.
                           should == Aji::Mention
    end

    it "creates author object if missing" do
      expect { Aji::Parsers::Tweet.parse(MultiJson.decode(@valid_json)) }.to
        change { Aji::Account::Twitter.find_by_uid('178492493')}.to(true)
    end
  end

  context "when a duplicate mention is passed" do
    before :each do
      @mention = Aji::Parsers::Tweet.parse(@valid_json).save
    end
    it "returns nil" do
      Aji::Parsers::Tweet.parse(@valid_json) do |tweet_hash|
        Aji::MentionProcessor.video_filters['twitter'][tweet_hash]
      end
    end
  end
end
