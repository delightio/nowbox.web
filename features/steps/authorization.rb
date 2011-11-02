class TwitterAuthorization < Spinach::FeatureSteps
  include Aji
  include TestUtils

  feature 'Twitter Authorization'

  Given 'this account has never been authorized before' do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:twitter] = TWITTER_HASH
  end

  @vcr
  When 'the callback url is triggered with a user_id' do
    VCR.use_cassette "twitter/home_feed" do
      @user = Aji::User.create
      get "auth/twitter/callback?user_id=#{@user.id}"

      @response = last_response
    end
  end

  Then 'the status code should be 200' do
    @response.status.should == 200
  end

  And 'there should be no errors' do
    @response.body.should_not =~ /error/i
  end
end
