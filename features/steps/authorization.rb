class Authorization < Spinach::FeatureSteps
  include Aji
  include TestUtils

  feature 'Authorization'

  Given 'this twitter account has never been authorized before' do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:twitter] = TWITTER_HASH
  end

  Given  'this youtube account has never been authorized before' do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:you_tube] = YOUTUBE_HASH
  end

  When 'the twitter callback url is triggered with a user_id' do
    VCR.use_cassette "twitter/home_feed" do
      @user = Aji::User.create
      get "auth/twitter/callback?user_id=#{@user.id}"
    end
  end

  When 'the youtube callback url is triggered with a user_id' do
    @user = Aji::User.create
    get "auth/you_tube/callback?user_id=#{@user.id}"
  end

  Then 'the status code should be 200' do
    last_response.status.should == 200
  end

  And 'there should be no errors' do
    last_response.body.should_not =~ /error/i
  end

  And 'the account should be linked with the user\'s identity' do
    @user.identity.accounts.map(&:uid).include?('nuclearsandwich').
      should == true
  end

  And 'a synchronization job should be enqueued' do
    j = MultiJson.decode Aji.redis.lpop("resque:queue:youtube_sync")
    j['class'].should == 'Aji::Queues::SynchronizeWithYoutube'
    j['args'].should == [@user.identity.youtube_account.id, false, "push_first"]
  end
end
