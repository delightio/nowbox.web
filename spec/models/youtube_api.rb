require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::YoutubeAPI do
    describe "#author_info" do
      it "gets info from youtube" do
        info = subject.author_info 'day9tv'
        info.description.should ==%(I grew up playing Starcraft with my brother, Nick (Tasteless). With the launch of Starcraft 2, I'm dedicated to helping the eSports movement grow in popularity around the world.

Watch my video autobiography here: http://www.youtube.com/watch?v=NJztfsXKcPQ)
        info.profile_uri.should == "http://www.youtube.com/profile?user=day9tv"
        info.thumbnail_uri.should == "http://i2.ytimg.com/i/axar6TBM-94_ezoS00fLkA/1.jpg?v=b5d95a"
        info.real_name.should == "Sean Day[9] Plott Plott"
      end
    end
  end
end
