class Authentication < Spinach::FeatureSteps
  include Aji
  include TestUtils

  feature 'Authentication'

  Given 'I have a user id and secret' do
    @user = User.create
  end

  When 'I securely request a token' do
    # TODO: Mock HTTPS-ness
    post "auth/request_token", :user_id => @user.id,
      :secret => Aji.conf['CLIENT_SECRET']
    @response = last_response
  end

  When 'I request a token' do
    # TODO: Mock no HTTPS
    post "auth/request_token", :user_id => @user.id,
      :secret => Aji.conf['CLIENT_SECRET']
    @response = last_response
  end

  Then 'I should receive a new token and time-to-live' do
    body = json_body @response

    body.should have_key? 'token'
    body.should have_key? 'ttl'
  end

  Then 'I should receive an error' do
    @response.body.should =~ /error.*must use HTTPS/
  end
end
