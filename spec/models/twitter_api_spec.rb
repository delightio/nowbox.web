require File.expand_path("../../spec_helper", __FILE__)
#require './spec/spec_config.rb'
#require 'twitter'
#require './models/twitter_api'
#require './models/mention'


# TODO: Only be authorized for the tests that need it!
module Aji
  describe Aji::TwitterAPI, :unit, :net do
    subject do
      TwitterAPI.new "RWUyehmqjKRBMSlVTeZDw",
        "BglumdMZZoYjosQIV8acdf9twivPrH15jE6AL2jmw",
        token: "178492493-AmMNGcEjYmK7OuCL7jNlPVv85yHGNmVmVMfJhTtN",
        secret: "DwRJZLB8UYAovc7L9fqavHvRPDNoFoX0IPM3V34z0"
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
      it "hits twitter only once" do
        subject.tracker.should_receive(:hit!)

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
  end
end
