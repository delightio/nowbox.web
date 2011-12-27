# encoding: utf-8

require File.expand_path("../../spec_helper", __FILE__)

include Aji
describe Aji::YoutubeAPI, :unit, :net do
  describe "#youtube_it_to_hash" do
    before :each do
      Account::Youtube.stub :create_or_find_by_lower_uid
      Category.stub :find_or_create_by_raw_title
      Category.stub :undefined
    end

    subject { YoutubeAPI.new }

    let(:video) { stub.as_null_object }

    let(:youtube_it_video_id) { "foobar12345" }

    let(:youtube_it_video) do
      mock :youtube_it_video,
        :categories => stub.as_null_object,
        :author => stub(:name => "foobar"),
        :title => "Foobar",
        :player_url => "http://youtube.com/v/#{youtube_it_video_id}",
        :description => "A Foobar video",
        :duration => 512431,
        :noembed => false,
        :view_count => 125152,
        :published_at => Time.now,
    end

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
      Account::Youtube.should_receive :create_or_find_by_lower_uid

      subject.youtube_it_to_hash video
    end

    it "returns a valid hash of video attributes" do
      subject.youtube_it_to_hash(video).keys.should == video_attributes
    end

    it "uses player_url for extracting external_id" do
      subject.youtube_it_to_hash(youtube_it_video)[:external_id].
        should == youtube_it_video_id
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
          video_upload_count thumbnail username total_upload_views]
          info['uid'].should == "day9tv"
          info['published'].should == Time.new(2010, 4, 22, 14, 48, 11, '-07:00')
          info['updated'].should > Time.new(2011, 9, 29, 07, 30, 00, '-07:00')
          info['category'].should == "Guru"
          info['title'].should == "day9tv"
          info['profile'].should == "http://www.youtube.com/profile?user=day9tv"
          info['homepage'].should == "http://day9.tv"
          info['about_me'].should ==%(I've qualified for the WCG USA finals 7 times, the WCG Grand Finals 3 times, and won the Pan American Championship in 2007 for StarCraft. In StarCraft 2 I play as random.\n\nI grew up playing Starcraft with my brother, Nick (Tasteless). With the launch of Starcraft 2, I'm dedicated to helping the eSports movement grow in popularity around the world.\n\nWatch my video autobiography here: http://www.youtube.com/watch?v=NJztfsXKcPQ)
          info['featured_video_id'].should match Link::YOUTUBE_ID_REGEXP
          info['first_name'].should == "Sean Day[9]"
          info['last_name'].should == "Plott"
          info['location'].should == "Los Angeles, CA, US"
          info['hobbies'].should == "Starcraft 2, Diablo 3, and other video games!"
          info['occupation'].should == "Starcraft 2 Player and Commentator"
          info['school'].should == "Harvey Mudd College, USC"
          info['subscriber_count'].should > 21000
          info['video_upload_count'].should >= 950
          info['thumbnail'].should == "http://i2.ytimg.com/i/axar6TBM-94_ezoS00fLkA/1.jpg?v=b5d95a"
          info['username'].should == "day9tv"
          info['total_upload_views'].should > 27000000
    end
  end

  context "when authenticated" do
    let(:token) { "1/MVVpQ67oY_0lEYs4JaYjLJa6RBPoxyej2_1e1AJdvkk" }
    let(:secret) { "G5B41-A-uFesmokk1n1tbyor" }
    let(:account_uid) { "nowmovnowbox" }

    subject { YoutubeAPI.new account_uid, token, secret }

    it "raises an error if partial credentials are used" do
      expect{ YoutubeAPI.new "someuser", "sometoken" }.to raise_error(
        ArgumentError)
    end

    it "creates an oauth client" do
      client = YoutubeAPI.new("nowmovnowbox", token, secret).send(:client)
      client.should be_kind_of YouTubeIt::OAuthClient
    end

    let(:subscribed_channels) { %w[raywilliamjohnson lisanova] }

    describe "#subscriptions" do
      it "returns subscribed channels" do
        channels = VCR.use_cassette "youtube_api/subscriptions" do
          subject.subscriptions
        end

        channels.should have(subscribed_channels.length).channels
        channels.map{|c| c.accounts.first.uid }.sort.
          should == subscribed_channels.sort
      end
    end

    describe "#subscribe_to" do
      before(:each) do
        VCR.use_cassette 'youtube_api/subscribe_to' do
          subject.unsubscribe_from channel_uid
        end
      end

      let(:channel_uid) { "lisanova" }

      it "hits youtube once" do
        subject.post_tracker.should_receive(:hit!).with(:post)
        VCR.use_cassette "youtube_api/subscribe_to" do
          subject.subscribe_to channel_uid
        end
      end

      it "subscribes given channel on YouTube" do
        VCR.use_cassette "youtube_api/subscribe_to" do
          subject.subscribe_to channel_uid
          subject.subscriptions.map{ |c| c.accounts.first.uid }.
            should include channel_uid
        end
      end

      it "does not raise an error when subscribing to a channel twice" do
        VCR.use_cassette "youtube_api/subscribe_to" do
          subject.subscribe_to channel_uid

          expect{ subject.subscribe_to channel_uid }.not_to raise_error
        end
      end
    end

    describe "#unsubscribe_from" do
      before(:each) do
       VCR.use_cassette 'youtube_api/unsubscribe_from' do
         subject.subscribe_to channel_uid
       end
      end

      let(:channel_uid) { "freddiew" }

      it "unsubscribes given channel" do
        VCR.use_cassette 'youtube_api/unsubscribe_from' do
          subject.unsubscribe_from channel_uid
          subject.subscriptions.map{ |c| c.accounts.first.uid }.
            should_not include channel_uid
        end
      end
    end

    describe "#favorite_videos" do
      let(:favorite_video_ids) { %w[dYCLXDtvrbs] }

      it "hits youtube once per page and once per new author" do
        subject.tracker.should_receive(:hit!).exactly(
          favorite_video_ids.length / 50 + 1).times

        favorite_videos = VCR.use_cassette "youtube_api/favorite_videos" do
          subject.favorite_videos
        end
      end

      it "returns user's favorite videos" do
        favorite_videos = VCR.use_cassette "youtube_api/favorite_videos" do
          subject.favorite_videos
        end

        favorite_videos.map(&:external_id).should == favorite_video_ids
      end

      it "gets the real author from the youtube api" do
        favorite_videos = VCR.use_cassette "youtube_api/favorite_videos" do
          subject.favorite_videos
        end

        favorite_videos.each do |v|
          v.author.uid.should_not == account_uid
        end
      end

      it "filters videos with nil ids" do
        favorite_videos = VCR.use_cassette "youtube_api/favorite_videos" do
          subject.favorite_videos
        end

        favorite_videos.select{ |v| v.external_id.nil? }.should be_empty
      end
    end

    describe "#add_to_favorites" do
      before(:each) { subject.remove_from_favorites external_id }
      let(:external_id) { "dYCLXDtvrbs" }

      it "hits youtube once" do
        subject.post_tracker.should_receive(:hit!).with(:post)
        VCR.use_cassette "youtube_api/add_to_favorites" do
          subject.add_to_favorites external_id
        end
      end

      it "adds given video to user's YouTube's favorite list" do
        subject.add_to_favorites external_id
        subject.favorite_videos.map(&:external_id).should include external_id
      end

      it "doesn't raise an error if video is already in favorites" do
        subject.add_to_favorites external_id
        expect do
          VCR.use_cassette "youtube_api/add_to_favorites" do
            subject.add_to_favorites external_id
          end
        end.not_to raise_error
      end
    end

    describe "#remove_from_favorites" do
      before(:each) { subject.add_to_favorites external_id }
      let(:external_id) { "zxmObqXYgI8" }

      it "removes given video from user's YouTube's favorite list" do
        subject.remove_from_favorites external_id

        subject.favorite_videos.map(&:external_id).
          should_not include external_id
      end

      it "doesn't raise an error if the video is not in favorites" do
        subject.remove_from_favorites external_id

        expect{ subject.remove_from_favorites external_id }.not_to raise_error
      end
    end

    describe "#add_to_watch_later" do
      before(:each) do
        VCR.use_cassette 'youtube_api/add_to_from_watch_later' do
          subject.remove_from_watch_later external_id
        end
      end

      let(:external_id) { "rqweCwAMan0" }

      it "hits youtube once" do
        subject.post_tracker.should_receive(:hit!).with(:post)
        VCR.use_cassette "youtube_api/add_to_watch_later" do
          subject.add_to_watch_later external_id
        end
      end

      it "adds a video to the watch later list" do
        VCR.use_cassette 'youtube_api/add_to_watch_later' do
          subject.add_to_watch_later external_id

          subject.watch_later_videos.map(&:external_id)
        end.should include external_id
      end

      it "doesn't raise an error if the video is already in watch later" do
        VCR.use_cassette 'youtube_api/add_to_watch_later' do
          subject.add_to_watch_later external_id

          expect{ subject.add_to_watch_later external_id }.not_to raise_error
        end
      end
    end

    describe "#remove_from_watch_later" do
      before(:each) do
        VCR.use_cassette 'youtube_api/remove_from_watch_later' do
          subject.add_to_watch_later external_id
        end
      end

      let(:external_id) { "rqweCwAMan0" }

      it "removes the video from watch later" do
        VCR.use_cassette 'youtube_api/remove_from_watch_later' do
          subject.remove_from_watch_later external_id

          subject.watch_later_videos
        end.map(&:external_id).should_not include external_id
      end

      it "doesn't raise an error if the video is not in watch later" do
        VCR.use_cassette 'youtube_api/remove_from_watch_later' do
          subject.remove_from_watch_later external_id

          expect{ subject.remove_from_watch_later external_id }.not_to raise_error
        end
      end
    end

    describe "#watch_later_videos" do
      let(:watch_later_video_ids) { %w[IsLwVoZqEjk] }

      it "returns user's watch later videos as Aji::Video objects" do
        videos = VCR.use_cassette "youtube_api/watch_later_videos" do
          subject.watch_later_videos
        end

        videos.map(&:external_id).should == watch_later_video_ids
      end

      it "gets the real author from the youtube api" do
        watch_later_videos = VCR.use_cassette "youtube_api/watch_later_videos" do
          subject.watch_later_videos
        end

        watch_later_videos.each do |v|
          v.author.uid.should_not == account_uid
        end
      end

      it "filters videos with nil ids" do
        videos = VCR.use_cassette "youtube_api/watch_later_videos" do
          subject.watch_later_videos
        end

        videos.select{ |v| v.external_id.nil? }.should be_empty
      end
    end


  end

  describe ".api" do
    it "initializes a new api instance when none is set" do
      YoutubeAPI.should_receive :new

      YoutubeAPI.api
    end

    it "uses a class instance variable to cache the singleton object" do
      YoutubeAPI.api.object_id.
        should == YoutubeAPI.instance_variable_get(:@singleton).object_id
    end
  end

  describe "#video_info" do
    it "hits youtube twice: 1 for video_info" do
      subject.tracker.should_receive(:hit!).once

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
      it "returns false if uid is not in ASCII" do
        subject.tracker.should_not_receive :hit!
        subject.valid_uid?("Südafrika").should be_false
      end

      it "hits youtube only once" do
        subject.tracker.should_receive(:hit!)

        VCR.use_cassette 'youtube_api/valid_author' do
          subject.valid_uid?("nowmovnowbox").should be_true
        end
      end

      specify "true if the uid belongs to a valid youtube account" do
        VCR.use_cassette 'youtube_api/valid_author' do
          subject.valid_uid?("nowmovnowbox").should be_true
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
    it "hits youtube once for the search and again for each author" do
      # TODO: VCR is giving us different results from our cache.
      # subject.tracker.should_receive(:hit!).exactly(1+unique_author_count).times
      result = VCR.use_cassette "youtube_api/keyword_search" do
        subject.keyword_search "harry potter"
      end

      unique_author = Set.new result.map &:author
      # Extra 5 to compensate for create_or_find behavior.
      subject.tracker.hit_count.should == (1+unique_author.length + 5)
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
      it "hits youtube once" do
        subject.tracker.should_receive(:hit!)

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
