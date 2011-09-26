require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe FacebookAPI do
    subject { FacebookAPI.new "AAACF78hfSZBEBAM0leS4CSzXZARd7S68Al6uVzs8DwJ8huZAm1YsjYeiZA2gBR3p7Ue8l3EPrKjkv6EtmOQuXo95aNTIcPIZD" }
    describe "#video_mentions_in_feed" do
      it "returns mentions with videos" do
        pending
        mentions = subject.video_mentions_in_feed
        mentions.each do |m|
          m.class.should_equal Mention, "Expected #{m.inspect} to be a Mention."
          m.videos.should_not be_empty, "Expected #{m.inspect} to have Videos."
        end
      end
    end
  end
end
