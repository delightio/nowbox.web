require File.expand_path("../../spec_helper", __FILE__)
module Aji
  describe Aji::YoutubeAPI do
    describe "#author_info" do
        subject.info.keys.sort.should == %w(description profile_uri thumbnail_uri)
        subject.info['description'].should ==%(I grew up playing Starcraft with my brother, Nick (Tasteless). With the launch of Starcraft 2, I'm dedicated to helping the eSports movement grow in popularity around the world.

Watch my video autobiography here: http://www.youtube.com/watch?v=NJztfsXKcPQ)
        subject.info['profile_uri'].should == "http://www.youtube.com/profile?user=day9tv"
        subject.info['thumbnail_uri'].should == "http://i2.ytimg.com/i/axar6TBM-94_ezoS00fLkA/1.jpg?v=b5d95a"
      end
    end
  end
end
