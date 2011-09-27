require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::TwitterAPI, :unit do
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

    describe "#videos_in_timeline" do
      it "returns an array of videos from a user's home timeline" do
        pending "Need to get valid OAuth Keys"
        videos = subject.videos_in_timeline
        videos.class.should == Array
        videos.all? { |v| v.class.should == Video }
      end
    end

    describe "API call counting"
  end
end
