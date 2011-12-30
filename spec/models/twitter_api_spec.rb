require File.expand_path("../../spec_helper", __FILE__)
#require './spec/spec_config.rb'
#require 'twitter'
#require './models/twitter_api'
#require './models/mention'

include Aji

# TODO: Only be authorized for the tests that need it!
describe Aji::TwitterAPI, :unit, :net do
  subject do
    TwitterAPI.new "wUhKhUtZKz39SvGRvcEXQ",
      "rJ0XLCxMChhcO0GK3vhRRLTg42T24m5rMov30Oav4ww",
      # uid: "14373489" # on staging
      token: "14373489-7eVCmhQkOWM5pFytjXSwN63MaCA8p5JOKMIktcqqG",
      secret: "fhQLo5aZQm3xYgwPoqCEYyNp2sPdfJSwRlb6dF6ss"
  end

  describe "#valid_uid?" do
    it "hits twitter only once" do
      subject.tracker.should_receive(:hit!)

      VCR.use_cassette "twitter_api/info_by_uid" do
        subject.valid_uid?('178492493')
      end
    end

    it "returns true if the user exists" do
      VCR.use_cassette "twitter_api/info_by_uid" do
        subject.valid_uid?('178492493').should be_true
      end
    end

    it "returns false if the user doesn't exist" do
      VCR.use_cassette "twitter_api/info_by_uid" do
        subject.valid_uid?('0').should be_false
      end
    end
  end

  describe "#video_mentions_i_post" do
    context "for unauthorized users" do
      subject { TwitterAPI.new uid: '178492493' }

      it "returns an array of video mentions by the user" do
        mentions = VCR.use_cassette "twitter_api/unauthed_user_timeline" do
          subject.video_mentions_i_post
        end

        mentions.should_not be_empty
        mentions.all? { |m| m.videos.should_not be_empty }
      end
    end

    it "hits twitter only once" do
      subject.tracker.should_receive(:hit!)

      VCR.use_cassette "twitter_api/user_timeline" do
        subject.video_mentions_i_post
      end

    end

    it "returns an array of video mentions by the authorized user" do
      mentions = VCR.use_cassette "twitter_api/user_timeline" do
        subject.video_mentions_i_post
      end

      mentions.should_not be_empty
      mentions.all? { |m| m.videos.should_not be_empty }
    end
  end

  describe "#valid_username?" do
    it "hits twitter only once" do
      subject.tracker.should_receive(:hit!)

      VCR.use_cassette "twitter_api/info_by_username" do
        subject.valid_username?('_nuclearsammich')
      end
    end

    it "returns true if the user exists" do
      VCR.use_cassette "twitter_api/info_by_username" do
        subject.valid_username?('_nuclearsammich').should be_true
      end
    end

    it "returns false if the user doesn't exist" do
      VCR.use_cassette "twitter_api/info_by_username" do
        subject.valid_username?('affenzhan').should be_false
      end
    end
  end

  describe "#video_mentions_in_feed" do
    it "hits twitter once per page" do
      subject.tracker.should_receive(:hit!).exactly(2).times

      VCR.use_cassette "twitter_api/home_timeline" do
        subject.video_mentions_in_feed
      end
    end

    it "returns an array of video mentions from a user's home timeline" do
      mentions = VCR.use_cassette "twitter_api/home_timeline" do
        subject.video_mentions_in_feed
      end
      mentions.should_not be_empty
      mentions.all? { |m| m.videos.should_not be_empty }
    end
  end

  describe "#publish" do
    let(:client) { stub.as_null_object }
    let(:body_text) { "I really hope this doesn't actually post to twitter" }

    it "hits twitter only once" do
      subject.instance_variable_set :@client, client
      subject.tracker.should_receive(:hit!)

      subject.publish body_text
    end

    it "posts text to twitter" do
      subject.instance_variable_set :@client, client
      client.should_receive(:update).with(body_text)

      subject.publish body_text
    end
  end
end
