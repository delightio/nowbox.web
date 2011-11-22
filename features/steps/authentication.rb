class Authentication < Spinach::FeatureSteps
  include Aji
  include TestUtils

  feature 'Authentication'

  Given 'I have a user id and secret' do
    @user = User.create
    @secret = Aji.conf['CLIENT_SECRET']
  end

  When 'I securely request a token' do
    puts User.find_by_id(@user.id).ai
    post "/auth/request_token", { :user_id => @user.id,
      :secret => @secret }, 'rack.url_scheme' => 'https'
    @response = last_response
  end

  When 'I request a token' do
    post "/auth/request_token", :user_id => @user.id,
      :secret => Aji.conf['CLIENT_SECRET']
    @response = last_response
  end

  Then 'I should receive a new token and time-to-live' do
    body = json_body @response
    puts body.ai

    body.has_key?('token').should == true
    body.has_key?('expires_at').should == true
  end

  Then 'I should receive an error' do
    @response.body.should =~ /error.*must use HTTPS/
  end

  Given 'a user id that isn\'t valid' do
    @user_id = 666
  end

  When 'a token is requested' do
    post "/auth/request_token", { :user_id => @user_id,
      :secret => Aji.conf['CLIENT_SECRET'] }, 'rack.url_scheme' => 'https'
  end

  Then 'the status should be 404' do
    last_response.status.should == 404
  end

  Then 'there should be an error' do
    last_response.body.should =~ /error/
  end
end
