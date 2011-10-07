require File.expand_path("../../spec_helper", __FILE__)
#require './spec/spec_config.rb'
#require 'twitter'
#require './models/twitter_api'
#require './models/mention'


module Aji
  describe Aji::TwitterAPI, :unit, :net do
    before :all do
      VCR.config do |c|
        c.cassette_library_dir = "spec/cassettes"
        c.stub_with :typhoeus
        c.default_cassette_options = { :record => :new_episodes }
      end
    end

    subject do
      TwitterAPI.new "178492493-AmMNGcEjYmK7OuCL7jNlPVv85yHGNmVmVMfJhTtN",
        "DwRJZLB8UYAovc7L9fqavHvRPDNoFoX0IPM3V34z0", "RWUyehmqjKRBMSlVTeZDw",
        "BglumdMZZoYjosQIV8acdf9twivPrH15jE6AL2jmw"
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
