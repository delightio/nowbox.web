class YoutubeSynchronization < Spinach::FeatureSteps
  include Aji

  feature 'Youtube Synchronization'

  Given 'a user authorized with youtube' do
    @user = User.create
    @account = Account::Youtube.from_auth_hash YOUTUBE_HASH
    Authorization.new(@account, @user.identity).grant!
  end

  When 'favoriting a video' do
    VCR.use_cassette "youtube/atomic_interactions" do
      @video = Video.create! source: :youtube, external_id: 'y4sOfO8Ei1g'
      @video.populate

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
      @user.favorite_video @video, Time.now
      @user.unfavorite_video @video
    end
  end

  Then 'that video should not be a youtube favorite' do
    @account.api.favorite_videos.include?(@video).should == false
  end

  When 'enqueueing a video' do
    VCR.use_cassette "youtube/atomic_interactions" do
      @video = Video.create! source: :youtube, external_id: 'y4sOfO8Ei1g'
      @video.populate
      @user.enqueue_video @video, Time.now
    end
  end

  Then 'that video should be in the watch later playlist on youtube' do
    VCR.use_cassette "youtube/atomic_interactions" do
      @account.api.watch_later_videos.include?(@video).should == true
    end
  end

  When 'dequeueing a video' do
    @video = Video.create! source: :youtube, external_id: 'y4sOfO8Ei1g'
    VCR.use_cassette "youtube/atomic_interactions" do
      @video.populate
      @user.enqueue_video @video, Time.now
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

      @user.subscribe @channel
      @user.unsubscribe @channel
    end
  end

  Then 'that channel should not be subscribed on youtube' do
    VCR.use_cassette "youtube/atomic_interactions" do
      @account.api.subscriptions.include?(@channel).should == false
    end
  end

  When 'a synchronization occurs' do
    raise 'step not implemented'
  end

  Then 'all channels from youtube should be in the user\'s subscribed channels' do
    raise 'step not implemented'
  end

  And 'all videos favorited on youtube should be in the user\'s favorites' do
    raise 'step not implemented'
  end

  And 'all videos in the watch later playlist should be in the user\'s favorites' do
    raise 'step not implemented'
  end
end
