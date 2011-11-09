class YoutubeSynchronization < Spinach::FeatureSteps
  include Aji

  feature 'Youtube Synchronization'

  Given 'a user authorized with youtube' do
    @user = User.create
    @account = Account::Youtube.from_auth_hash YOUTUBE_HASH
    Authorization.new(@account, @user.identity).grant!
  end

  When 'favoriting a video that is not currently favorited' do
    VCR.use_cassette "youtube/atomic_interactions" do
      @video = Video.create! source: :youtube, external_id: 'y4sOfO8Ei1g'
      @video.populate
      @account.api.remove_from_favorites @video if @account.api.favorite_videos.
        include? @video

      @user.favorite_video @video, Time.now
    end
  end

  Then 'that video should be a youtube favorite' do
    VCR.use_cassette "youtube/atomic_interactions" do
      @account.api.favorite_videos.include?(@video).should == true
    end
  end

  When  'unfavoriting a currently favorited video' do
    VCR.use_cassette "youtube/atomic_interactions" do
      @video = Video.create! source: :youtube, external_id: 'y4sOfO8Ei1g'
      @video.populate
      @account.api.add_to_favorites @video unless @account.api.favorite_videos.
        include? @video

      @user.unfavorite_video @video
    end
  end

  Then 'that video should not be a youtube favorite' do
    VCR.use_cassette "youtube/atomic_interactions" do
      @account.api.favorite_videos.include?(@video).should == false
    end
  end

  When 'enqueueing a video that is not currently in watch later' do
    fail "Not yet implemented"
    VCR.use_cassette "youtube/atomic_interactions" do
      @video = Video.create! source: :youtube, external_id: 'y4sOfO8Ei1g'
      @video.populate
      @user.enqueue_video @video, Time.now
    end
  end

  Then 'that video should be in the watch later playlist on youtube' do
    fail "Not yet implemented"
    VCR.use_cassette "youtube/atomic_interactions" do
      @account.api.watch_later_videos.include?(@video).should == true
    end
  end

  When 'dequeueing a video that is currently in watch later' do
    fail "Not yet implemented"
    @video = Video.create! source: :youtube, external_id: 'y4sOfO8Ei1g'
    VCR.use_cassette "youtube/atomic_interactions" do
      @video.populate
      # PENDING Watch Later impelementation in YouTubeIt.
      #@account.api.add_to_watch_later @video

      @user.dequeue_video @video
    end
  end

  Then 'that video should not be in the watch later playlist on youtube' do
    VCR.use_cassette "youtube/atomic_interactions" do
      @account.api.watch_later_videos.include?(@video).should == false
    end
  end

  When 'subscribing to a channel' do
    VCR.use_cassette "youtube/atomic_interactions" do
      @channel = Channel::Account.create!(
        accounts: [Account::Youtube.create(uid: "thedoctorwhomedia")])

        @user.subscribe @channel
      end
  end

  Then 'that channel should be subscribed on youtube' do
    VCR.use_cassette "youtube/atomic_interactions" do
      @account.api.subscriptions.include?(@channel).should == true
    end
  end

  When 'unsubscribing from a channel' do
    VCR.use_cassette "youtube/atomic_interactions" do
      @channel = Channel::Account.create!(
        accounts: [Account::Youtube.create(uid: "freddiew")])
      @account.api.subscribe_to @channel

      @user.unsubscribe @channel
    end
  end

  Then 'that channel should not be subscribed on youtube' do
    VCR.use_cassette "youtube/atomic_interactions" do
      @account.api.subscriptions.include?(@channel).should == false
    end
  end

  When 'a synchronization occurs' do
    YoutubeSync.new(@account)
  end

  Then 'all channels from youtube should be in the user\'s subscribed channels' do
    VCR.use_cassette "youtube/atomic_interactions" do
      @account.api.subscriptions.each do |subscribed_channel|
        puts "!!!", subscribed_channel, "!!!"
        puts @user.youtube_channels.count
        puts @user.youtube_channels
        @user.youtube_channels.include?(subscribed_channel).should == true
      end
    end
  end

  And 'all videos favorited on youtube should be in the user\'s favorites' do
    VCR.use_cassette "youtube/atomic_interactions" do
      @account.api.favorite_videos.each do |favorite_video|
        @user.favorite_videos.include?(favorite_video).should == true
      end
    end
  end

  And 'the next synchronization should be scheduled' do
    j = MultiJson.decode Aji.redis.lpop(Aji.redis.keys("resque:delayed:*")[0])
    j['queue'].should == 'youtube_sync'
    j['args'].should == @account.id
  end

  And 'all videos in the watch later playlist should be in the user\'s favorites' do
    fail "Not yet implemented"
  end
end
