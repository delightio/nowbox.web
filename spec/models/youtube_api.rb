require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::YoutubeAPI, :unit, :net do
    describe "#author_info" do
      it "gets info from youtube" do
        info = VCR.use_cassette "youtube_api/author" do
          subject.author_info 'day9tv'
        end

        info.description.should ==%(I grew up playing Starcraft with my brother, Nick (Tasteless). With the launch of Starcraft 2, I'm dedicated to helping the eSports movement grow in popularity around the world.

Watch my video autobiography here: http://www.youtube.com/watch?v=NJztfsXKcPQ)
        info.profile_uri.should == "http://www.youtube.com/profile?user=day9tv"
        info.thumbnail_uri.should == "http://i2.ytimg.com/i/axar6TBM-94_ezoS00fLkA/1.jpg?v=b5d95a"
        info.realname.should == "Sean Day[9] Plott Plott"
      end
    end

    describe "#video_info" do
      it "gives information about a video in a hash" do
        hash = VCR.use_cassette "youtube_api/video" do
          subject.video_info '3307vMsCG0I'
        end

        hash[:title].should == "[Portal 2] Corrupt Core Quotes (Space, Fact and Adventure Spheres)"
        hash[:external_id].should == "3307vMsCG0I"
        hash[:description].should == "Here are all the lines for the corrupt cores during the final fight scene. Not gunna lie, i couldnt stop laughing during the final battle because of these little bastards.   Anyways, Enjoy, Comment, Rate, Subscribe, Share! :D"
      end

      it "raises a VideoAPI::Error when video is unavailable" do
        VCR.use_cassette "youtube_api/bad_video" do
          expect { subject.video_info("foobarbazqu") }.to(
            raise_error Aji::VideoAPI::Error)
        end
      end
    end
  end
end
