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
        end
      end
      
      describe "post #{resource_uri}/:id" do
        it "should create user object on post with default channel listing" do
          default_channels = []
          5.times { |n| default_channels << Factory(:channel_with_videos, :default_listing=>true)}
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
      
      describe "put #{resource_uri}/:id" do
        it "should only respond to known commands" do
          channel = Factory :channel_with_videos
          user = Factory :user
          params = {:channel_id => channel.id, :channel_action => random_string}
          put "#{resource_uri}/#{user.id}", params
          last_response.status.should == 400
        end

        it "should allow subscribing" do
          channel = Factory :channel_with_videos
          user = Factory :user
          params = {:channel_id => channel.id, :channel_action => :subscribe}
          put "#{resource_uri}/#{user.id}", params
          last_response.status.should == 200
          user.subscribed_channels.should include channel
        end

        it "should allow unsubscribing" do
          channel = Factory :channel_with_videos
          user = Factory :user
          user.subscribe channel
          params = {:channel_id => channel.id, :channel_action => :unsubscribe}
          put "#{resource_uri}/#{user.id}", params
          last_response.status.should == 200
          user.subscribed_channels.should_not include channel
        end

        it "should allow channel arrangment" do
          user = Factory :user
          channels = []
          5.times do |n|
            channels << Factory(:channel)
            user.subscribe channels.last
          end
          old_position = 3
          new_position = 1
          channel = channels[old_position]
          params = {:channel_id => channel.id, :channel_action => :arrange, :channel_action_params=>{:new_position=>new_position}}
          put "#{resource_uri}/#{user.id}", params
          last_response.status.should == 200
          user.subscribed_channels[new_position].should == channel
        end
      end
      
    end
  end
end