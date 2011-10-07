require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe FacebookAPI, :unit, :net do
    before :all do
      VCR.config do |c|
        c.cassette_library_dir = "spec/cassettes"
        c.stub_with :typhoeus
        c.default_cassette_options = { :record => :new_episodes }
      end
    end

    subject do
      FacebookAPI.new "AAACF78hfSZBEBAM0leS4CSzXZARd7S68Al6uVzs8DwJ8huZAm1YsjYeiZA2gBR3p7Ue8l3EPrKjkv6EtmOQuXo95aNTIcPIZD"
    end

    describe "#video_mentions_in_feed" do
      it "hits facebook once per page" do
        subject.tracker.should_receive(:hit!).exactly(5).times
        VCR.use_cassette "facebook_api/home_feed" do
          subject.video_mentions_in_feed
        end

        subject.tracker.should_receive(:hit!).exactly(4).times
        VCR.use_cassette "facebook_api/home_feed" do
          subject.video_mentions_in_feed 4
        end
      end

      it "returns mentions with videos" do
        mentions = VCR.use_cassette "facebook_api/home_feed" do
          subject.video_mentions_in_feed
        end

        mentions.each do |m|
          m.videos.should_not be_empty, "Expected #{m.inspect} to have Videos."
        end
      end
    end

    describe "#video_mentions_i_post" do
      pending "This method is almost _never_ useful. I may remove it"
    end
  end
end
