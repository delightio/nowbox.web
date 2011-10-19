require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::YoutubeAPI, :unit, :net do

    describe "#youtube_it_to_hash" do
      before :each do
        Account::Youtube.stub :find_or_create_by_lower_uid
        Category.stub :find_or_create_by_raw_title
        Category.stub :undefined
      end

      let(:video) { stub.as_null_object }
      let(:video_attributes) do
        [:title, :external_id, :description, :duration, :viewable_mobile,
          :view_count, :category, :author, :published_at, :source,
          :populated_at]
      end

      it "gets a category when a category is specified" do
        video.stub :categories => [stub(:label => "label", :term => "term")]
        Category.should_receive :find_or_create_by_raw_title

        subject.youtube_it_to_hash video
      end

      it "uses the undefined category when none is specified" do
        video.stub :categories => []
        Category.should_receive :undefined

        subject.youtube_it_to_hash video
      end

      it "creates Account::Youtube object if needed" do
        Account::Youtube.should_receive :find_or_create_by_lower_uid

        subject.youtube_it_to_hash video
      end

      it "returns a valid hash of video attributes" do
        subject.youtube_it_to_hash(video).keys.should == video_attributes
      end
    end

    describe "#youtube_it_to_video" do
      let(:video) { mock("youtube it video") }

      let(:video_hash) do
        {
          :title => "A Video",
          :external_id => "1234567890-",
          :description => "Hilarious Video",
          :duration => 320.seconds,
          :viewable_mobile => true,
          :view_count => 111,
          :category => Category.new,
          :author => Account::Youtube.new,
          :published_at => 4.hours.ago,
          :source => :youtube,
          :populated_at => Time.now
        }
      end

      it "returns an valid video from database" do
        subject.should_receive(:youtube_it_to_hash).with(video).and_return(
          video_hash)

        subject.youtube_it_to_video(video).should be_valid
      end
    end

    describe "#author_info" do
      it "hits youtube only once" do
        subject.tracker.should_receive(:hit!)

        info = VCR.use_cassette "youtube_api/author" do
          subject.author_info 'day9tv'
        end
      end

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
      it "hits youtube twice: 1 for video_info call and 1 for author_info" do
        subject.tracker.should_receive(:hit!).twice

         hash = VCR.use_cassette "youtube_api/video" do
           subject.video_info '3307vMsCG0I'
         end
      end

      it "gives information about a video in a hash" do
        hash = VCR.use_cassette "youtube_api/video" do
          subject.video_info '3307vMsCG0I'
        end

        hash[:title].should == "[Portal 2] Corrupt Core Quotes (Space, Fact and Adventure Spheres)"
        hash[:external_id].should == "3307vMsCG0I"
        hash[:description].should == "Here are all the lines for the corrupt cores during the final fight scene. Not gunna lie, i couldnt stop laughing during the final battle because of these little bastards.   Anyways, Enjoy, Comment, Rate, Subscribe, Share! :D"
        hash[:source].should == :youtube
      end

      it "raises a VideoAPI::Error when video is unavailable" do
        VCR.use_cassette "youtube_api/bad_video" do
          expect { subject.video_info("foobarbazqu") }.to(
            raise_error Aji::VideoAPI::Error)
        end
      end

      describe "#valid_uid?" do
        it "hits youtube only once" do
          #pending "please check actual hits required since we always create author object in db"

          subject.tracker.should_receive(:hit!)

          VCR.use_cassette 'youtube_api/valid_author' do
            subject.valid_uid?("nuclearsandwich").should be_true
          end
        end

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

    describe "#keyword_search" do
      it "hits youtube once for the search and again for each new author" do
        unique_author_count = 43
        subject.tracker.should_receive(:hit!).exactly(1+unique_author_count).times
        VCR.use_cassette "youtube_api/keyword_search" do
          subject.keyword_search "george carlin"
        end
      end

      it "returns a nonempty collection of populated videos from db" do
        videos = VCR.use_cassette "youtube_api/keyword_search" do
          subject.keyword_search "george carlin"
        end

        videos.should_not be_empty
        videos.each do |v|
          v.should_not be_new_record
          v.should be_populated
        end
      end
    end

    context "for a user with uploaded content" do
      subject { YoutubeAPI.new "brentalfloss" }

      describe "#uploaded_videos" do
        it "hits youtube twice: 1 for video_info call and 1 for author_info" do
          subject.tracker.should_receive(:hit!).twice

          videos = VCR.use_cassette "youtube_api/uploaded_videos" do
            subject.uploaded_videos
          end
        end

        it "returns a nonempty list of populated videos from db" do
          videos = VCR.use_cassette "youtube_api/uploaded_videos" do
            subject.uploaded_videos
          end

          videos.should_not be_empty
          videos.each do |v|
            v.should_not be_new_record
            v.should be_populated
          end
        end
      end
    end
  end
end
