require File.expand_path("../../spec_helper", __FILE__)

module Aji
  resource = "channels"
  resource_uri = "/#{API.version.first}/#{resource}"

  describe API do
    describe "resource: #{resource}" do

      describe "get #{resource_uri}" do
        it "should return all default channels" do
          channels = []
          total = 5
          total.times {|n| channels << Factory(:channel_with_videos,:default_listing=>false) }
          default = [0,1,2,3,4].sample(2)
          channels[default.first].update_attributes :default_listing => true
          channels[default.last].update_attributes :default_listing => true
          get "#{resource_uri}"
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          returned_channels = body_hash.map {|h| h["channel"]}
          returned_channels.should include channels[default.first].serializable_hash
          returned_channels.should include channels[default.last].serializable_hash
        end
      end

      describe "get #{resource_uri}/:id" do
        it "should return 404 if not found" do
          get "#{resource_uri}/#{rand(100)}"
          last_response.status.should == 404
        end

        it "should channel info if found" do
          channel = Factory :channel_with_videos
          get "#{resource_uri}/#{channel.id}"
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          body_hash.should == channel.serializable_hash
        end
      end

      describe "post #{resource_uri}/:id" do
        it "should create new channel"
      end

      describe "put #{resource_uri}/:id" do
        it "should only respond to known commands" do
          channel = Factory :channel_with_videos
          user = Factory :user
          params = {:user_id => user.id, :channel_action => random_string}
          put "#{resource_uri}/#{channel.id}", params
          last_response.status.should == 400
        end

        it "should allow subscribing" do
          channel = Factory :channel_with_videos
          user = Factory :user
          params = {:user_id => user.id, :channel_action => :subscribe}
          put "#{resource_uri}/#{channel.id}", params
          last_response.status.should == 200
        end

        it "should allow unsubscribing" do
          channel = Factory :channel_with_videos
          user = Factory :user
          user.subscribe channel
          params = {:user_id => user.id, :channel_action => :unsubscribe}
          put "#{resource_uri}/#{channel.id}", params
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
          params = {:user_id => user.id, :channel_action => :arrange, :channel_action_params=>{:new_position=>new_position}}
          put "#{resource_uri}/#{channel.id}", params
          last_response.status.should == 200
          user.subscribed_channels[new_position] = channel
        end
      end

      describe "get #{resource_uri}/:id/videos" do
        it "should respect limit params" do
          limit = 3
          channel = Factory :channel_with_videos
          channel.content_videos.count.should > limit
          user = Factory :user
          params = {:user_id=>user.id, :limit=>3}
          get "#{resource_uri}/#{channel.id}/videos", params
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          body_hash.count.should == limit
        end
        
        it "should not returned viewed videos" do
          channel = Factory :channel_with_videos
          viewed_video = channel.content_videos.sample
          user = Factory :user
          event = Factory :event, :event_type => :view, :user => user, :video => viewed_video
          params = {:user_id => user.id }
          get "#{resource_uri}/#{channel.id}/videos", params
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          video_ids = body_hash.map {|h| h["video"]["id"]}
          video_ids.should_not include viewed_video.id
        end
      end

    end
  end
end
