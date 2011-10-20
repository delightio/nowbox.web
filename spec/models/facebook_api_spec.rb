require File.expand_path("../../spec_helper", __FILE__)

module Aji
  # Lost unit designation due to dependence on MentionProcessor class.
  describe FacebookAPI, :net do
    subject do
      FacebookAPI.new "AAACF78hfSZBEBAM0leS4CSzXZARd7S68Al6uVzs8DwJ8huZAm1YsjYeiZA2gBR3p7Ue8l3EPrKjkv6EtmOQuXo95aNTIcPIZD"
    end

    describe "#video_mentions_in_feed" do
      it "hits facebook once per page" do
        VCR.use_cassette "facebook_api/home_feed" do
          subject.tracker.should_receive(:hit!).exactly(5).times
          subject.video_mentions_in_feed

          subject.tracker.should_receive(:hit!).exactly(4).times
          subject.video_mentions_in_feed 4
        end
      end

      it "returns mentions with videos" do
        VCR.use_cassette "facebook_api/home_feed" do
          subject.video_mentions_in_feed.each do |m|
            m.videos.should_not be_empty, "Expected #{m.inspect} to have Videos"
          end
        end
      end

      it "doesn't fail from nil pages" do
        VCR.use_cassette "facebook_api/home_feed" do
          Koala::Facebook::GraphCollection.any_instance.stub(
            :next_page).and_return(nil)

          expect{ subject.video_mentions_in_feed }.to_not raise_error
        end
      end
    end

    describe "#video_mentions_i_post" do
      VCR.use_cassette "facebook_api/home_feed" do
        pending "This method is almost _never_ useful. I may remove it"
      end
    end
  end
end
