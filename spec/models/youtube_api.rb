require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::YoutubeAPI, :unit, :net do
    before :all do
      VCR.config do |c|
        c.cassette_library_dir = "spec/cassettes"
        c.stub_with :typhoeus
        c.default_cassette_options = { :record => :new_episodes }
      end
    end

    describe "#author_info" do
      it "retrieves a hash of information from youtube" do
        info = VCR.use_cassette "youtube_api/author" do
          subject.author_info 'day9tv'
        end

        info.keys.should == %w[uid published updated
          category title profile homepage featured_video_id about_me first_name
          last_name hobbies location occupation school subscriber_count
          thumbnail username total_upload_views]
        info['uid'].should == "day9tv"
        info['published'].should == Time.new(2010, 4, 22, 14, 48, 11, '-07:00')
        info['updated'].should > Time.new(2011, 9, 29, 07, 30, 00, '-07:00')
        info['category'].should == "Guru"
        info['title'].should == "YouTube user: day9tv"
        info['profile'].should == "http://www.youtube.com/profile?user=day9tv"
        info['homepage'].should == "http://day9.tv"
        info['about_me'].should ==%(I grew up playing Starcraft with my brother, Nick (Tasteless). With the launch of Starcraft 2, I'm dedicated to helping the eSports movement grow in popularity around the world.

Watch my video autobiography here: http://www.youtube.com/watch?v=NJztfsXKcPQ)
        info['featured_video_id'].should match Link::YOUTUBE_ID_REGEXP
        info['first_name'].should == "Sean Day[9] Plott"
        info['last_name'].should == "Plott"
        info['location'].should == "Los Angeles, CA, US"
        info['hobbies'].should == "Starcraft 2"
        info['occupation'].should == "Starcraft 2 Player and Commentator"
        info['school'].should == "Harvey Mudd College, USC"
        info['subscriber_count'].should > 21000
        info['thumbnail'].should == "http://i2.ytimg.com/i/axar6TBM-94_ezoS00fLkA/1.jpg?v=b5d95a"
        info['username'].should == "day9tv"
        info['total_upload_views'].should > 27000000
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

      describe "#valid_uid?" do
        specify "true if the uid belongs to a valid youtube account" do
          VCR.use_cassette 'youtube_api/valid_author' do
            subject.valid_uid?("nuclearsandwich").should be_true
          end
        end

        specify "false otherwise" do
          VCR.use_cassette 'youtube_api/invalid_author' do
            subject.valid_uid?("noaosldfads").should be_false
          end
        end
      end
    end
  end
end
