require File.expand_path("../../spec_helper", __FILE__)

module Aji
  resource = "users"
  resource_uri = "/#{API.version.first}/#{resource}"

  describe API do
    describe "resource: #{resource}" do
      
      describe "get #{resource_uri}/:id" do
        it "should return 404 if not found" do
          get "#{resource_uri}/#{rand(100)}"
          last_response.status.should == 404
        end
        
        it "should return user info if found" do
          user = Factory :user_with_channels
          channel_ids = user.subscribed_list
          get "#{resource_uri}/#{user.id}"
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          body_hash.should == user.serializable_hash
          body_hash["subscribed_channel_ids"].should == user.subscribed_channels.map {|c| c.id.to_s}
          [:queue_channel_id, :favorite_channel_id, :history_channel_id].each do |c|
            body_hash[c.to_s].should == (user.send c)
          end
        end
      end
      
      describe "post #{resource_uri}/:id" do
        it "should create user object on post with default channel listing" do
          default_channels = []
          5.times { |n| default_channels << Factory(:youtube_channel_with_videos, :default_listing=>true)}
          email = random_email
          first_name = random_string
          params = { :email => email, :first_name => first_name, :last_name => random_string }
          post "#{resource_uri}/", params
          last_response.status.should ==201
          user_hash = JSON.parse last_response.body
          user_hash["first_name"].should == first_name
          u = User.find user_hash["id"] # ensure we can look up the user again
          u.email.should == email
          default_channels.each do |c|
            u.subscribed_channels.should include c
          end
        end
      end
      
    end
  end
end