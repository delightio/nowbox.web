require File.expand_path("../../spec_helper", __FILE__)
#require './spec/spec_config.rb'
#require 'twitter'
#require './models/twitter_api'
#require './models/mention'


module Aji
  describe Aji::TwitterAPI, :unit, :net do
    subject do
      TwitterAPI.new "178492493-AmMNGcEjYmK7OuCL7jNlPVv85yHGNmVmVMfJhTtN",
        "DwRJZLB8UYAovc7L9fqavHvRPDNoFoX0IPM3V34z0", "RWUyehmqjKRBMSlVTeZDw",
        "BglumdMZZoYjosQIV8acdf9twivPrH15jE6AL2jmw"
    end

    describe "#valid_uid?" do
      it "returns true if the user exists" do
        subject.valid_uid?('178492493').should be_true
      end

      it "returns false if the user doesn't exist" do
        subject.valid_uid?('0').should be_false
      end
    end

    describe "#valid_username?" do
      it "returns true if the user exists" do
        subject.valid_username?('_nuclearsammich').should be_true
      end

      it "returns false if the user doesn't exist" do
        subject.valid_username?('affenzhan').should be_false
      end
    end

    describe "#video_mentions_in_feed" do
      it "returns an array of video mentions from a user's home timeline" do
        mentions = subject.video_mentions_in_feed
        mentions.should_not be_empty
        mentions.all? { |m| m.videos.should_not be_empty }
      end
    end

    describe "API call counting"
  end
end
