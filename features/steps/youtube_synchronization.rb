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
      @user.favorite_video @video, Time.now
    end
  end

  Then 'that video should be queued to be added to favorites' do
    j = MultiJson.decode Aji.redis.lpop("resque:queue:background_youtube_request")
    j['class'].should == 'Aji::Queues::BackgroundYoutubeRequest'
    j['args'][1..-1].should == ['add_to_favorites', 'y4sOfO8Ei1g']
  end

  When  'unfavoriting a currently favorited video' do
    VCR.use_cassette "youtube/atomic_interactions" do
      @video = Video.create! source: :youtube, external_id: 'y4sOfO8Ei1g'
      @video.populate
      @user.unfavorite_video @video
    end
  end

  Then 'that video should be queued to be removed from favorites' do
    j = MultiJson.decode Aji.redis.lpop("resque:queue:background_youtube_request")
    j['class'].should == 'Aji::Queues::BackgroundYoutubeRequest'
    j['args'][1..-1].should == ['remove_from_favorites', 'y4sOfO8Ei1g']
  end

  When 'enqueueing a video that is not currently in watch later' do
    VCR.use_cassette "youtube/atomic_interactions" do
      @video = Video.create! source: :youtube, external_id: 'y4sOfO8Ei1g'
      @video.populate
      @user.enqueue_video @video, Time.now
    end
  end

  Then 'that video should be queued to be added to watch later' do
    j = MultiJson.decode Aji.redis.lpop("resque:queue:background_youtube_request")
    j['class'].should == 'Aji::Queues::BackgroundYoutubeRequest'
    j['args'][1..-1].should == ['add_to_watch_later', 'y4sOfO8Ei1g']
  end

  When 'dequeueing a video that is currently in watch later' do
    @video = Video.create! source: :youtube, external_id: 'y4sOfO8Ei1g'

    VCR.use_cassette "youtube/atomic_interactions" do
      @video.populate
      @user.dequeue_video @video
    end
  end

  Then 'that video should be queued to be removed from watch later' do
    j = MultiJson.decode Aji.redis.lpop("resque:queue:background_youtube_request")
    j['class'].should == 'Aji::Queues::BackgroundYoutubeRequest'
    j['args'][1..-1].should == ['remove_from_watch_later', 'y4sOfO8Ei1g']
  end

  When 'subscribing to a channel' do
    VCR.use_cassette "youtube/atomic_interactions" do
      @channel = Channel::Account.create!(
        accounts: [Account::Youtube.create(uid: "thedoctorwhomedia")])

        @user.subscribe @channel
      end
  end

  Then 'that channel should be queued to be added to subscriptions' do
    j = MultiJson.decode Aji.redis.lpop("resque:queue:background_youtube_request")
    j['class'].should == 'Aji::Queues::BackgroundYoutubeRequest'
    j['args'][1..-1].should == ['subscribe_to', 'thedoctorwhomedia']
  end

  When 'unsubscribing from a channel' do
    VCR.use_cassette "youtube/atomic_interactions" do
      @channel = Channel::Account.create!(
        accounts: [Account::Youtube.create(uid: "freddiew")])

      @user.unsubscribe @channel
    end
  end

  Then 'that channel should be queued to be removed from subscriptions' do
    j = MultiJson.decode Aji.redis.lpop("resque:queue:background_youtube_request")
    j['class'].should == 'Aji::Queues::BackgroundYoutubeRequest'
    j['args'][1..-1].should == ['unsubscribe_from', 'freddiew']
  end

  When 'a synchronization occurs' do
    VCR.use_cassette "youtube/atomic_interactions" do
      YoutubeSync.new(@account).synchronize!
    end
  end

  Then 'all channels from youtube should be in the user\'s subscribed channels' do
    VCR.use_cassette "youtube/atomic_interactions" do
      @account.api.subscriptions.each do |subscribed_channel|
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
    j['args'].should == [@account.id]
  end

  And 'all videos in the watch later playlist should be in the user\'s queue' do
    VCR.use_cassette 'youtube/atomic_interactions' do
      @account.api.watch_later_videos.each do |watch_later_video|
        @user.queued_videos.include?(watch_later_video).should == true
      end
    end
  end
end
