class UsersApi < Spinach::FeatureSteps
  include Aji
  include TestUtils
  #include HTTPSteps #TODO: figure out how to factor steps into modules.


  use_api_subdomain!

  def subdomain
    :api
  end

  feature 'Users API'

  When 'a user is created with no parameters' do
    post "/1/users"
  end

  And 'no user is created' do
    User.count.should == 0
  end

  Given 'a user\'s locale and region' do
    (@parameters ||= {}).merge!({ :locale => "en", :region => "US" })
  end

  When 'a user is created with those parameters' do
    post "/1/users", @parameters
  end

  And 'the user should be created' do
    User.count.should == 1
  end

  And 'the user should have no name or email' do
    body = json_body last_response
    user = User.find body['id']

    user.name.should == nil
    user.email.should == nil
  end

  But 'the user should have favorites, queue, and history channels' do
    body = json_body last_response
    user = User.find body['id']

    Channel.find(body['favorites_channel_id']).should == user.favorites_channel
    Channel.find(body['queue_channel_id']).should == user.queue_channel
    Channel.find(body['history_channel_id']).should == user.history_channel
  end

  Given 'a user\'s name and email' do
    (@parameters ||= {}).merge!({:name => "Bob",
      :email => "bob@example.com" })
  end

  And 'the user should have that name, email, and region' do
    body = json_body last_response
    user = User.find(body['id'])

    user.name.should == @parameters[:name]
    user.email.should == @parameters[:email]
  end

  Given 'a valid token for a user' do
    @user = User.create
    @token = Token::Generator.new(@user).token
    header 'X-NB-AuthToken', @token
  end

  When 'getting that user\'s information' do
    get "/1/users/#{@user.id}"
  end

  And 'the user\'s information should be present' do
    body = json_body last_response

    %w[id subscribed_channel_ids queue_channel_id favorite_channel_id
       history_channel_id name email].each do |attribute|
         body.keys.include?(attribute).should == true
       end
  end

  When  'updating that user\'s info' do
    @user_attributes = { :name => "Bob", :email => "bob@bits.com" }
    put "/1/users/#{@user.id}", @user_attributes
  end

  When  'updating another user\'s info' do
    @other_user = User.create
    @user_attributes = { :name => "Sally", :email => "sall@sparrow.com" }
    put "/1/users/#{@other_user.id}", @user_attributes
  end

  When 'getting another user\'s information' do
    @other_user = User.create
    get "/1/users/#{@other_user.id}"
  end

  Given 'a valid user id' do
    @user = User.create
  end

  When 'updating that user\'s settings' do
    @settings =  { :post_to_twitter => true, :max_videos_per_channel => 600,
     :nickname => "Max" }
    put "/1/users/#{@user.id}/settings", :settings => @settings
  end

  Then 'the new settings should be present' do
    body = json_body last_response

    @settings.each do |key, value|
      key = key.to_s
      body.has_key?(key).should == true
      body[key].should == value
    end
  end

  When 'updating another user\'s settings' do
    @other_user = User.create
    @settings =  { :post_to_twitter => true, :max_videos_per_channel => 600,
     :nickname => "Max" }
    put "/1/users/#{@other_user.id}/settings", @settings
  end

  [200, 201, 400, 401, 403, 404].each do |code|
    Then "the status code should be #{code}" do
      last_response.status.should == code
    end
  end

  And 'there should be an error' do
    last_response.body.should =~ /error/
  end

  When  'testing that user\'s authentication' do
    get "/1/users/#{@user.id}/auth_test"
  end

  When  'testing another user\'s authentication' do
    @other_user = User.create
    get "/1/users/#{@other_user.id}/auth_test"
  end
end

