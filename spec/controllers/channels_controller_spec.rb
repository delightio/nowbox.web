require File.expand_path("../../spec_helper", __FILE__)

module Aji
  resource = "channels"
  resource_uri = "/#{API.version.first}/#{resource}"

  describe API do
    describe "resource: #{resource}" do

      describe "get #{resource_uri}/:id" do
        it "returns 404 if not found" do
          cid = rand(100)
          Channel.find_by_id(cid).should be_nil
          get "#{resource_uri}/#{cid}"
          last_response.status.should == 404
        end
        
        it 'returns channel object if found' do
          c = Factory :youtube_channel_with_videos
          get "#{resource_uri}/#{c.id}"
          last_response.status.should == 200
        end
      end
      
      describe "get #{resource_uri}" do
        it "always create keyword channel based on query" do
          pending
          query = random_string
          params = { :query => query, :user_id => (Factory :user).id }
          expect { get "#{resource_uri}", params }.to change { Channel.count }.by(1)
        end
      end
      
      describe "get #{resource_uri}" do
        it "should return all default channels" do
          channels = []
          total = 5
          total.times {|n| channels << Factory(:youtube_channel_with_videos,:default_listing=>false) }
          default = [0,1,2,3,4].sample(2)
          channels[default.first].update_attributes :default_listing => true
          channels[default.last].update_attributes :default_listing => true
          get "#{resource_uri}"
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          returned_channels = body_hash.map {|h| h["youtube_account"]}
          returned_channels.should include channels[default.first].serializable_hash
          returned_channels.should include channels[default.last].serializable_hash
        end
        
        it "should return subscribed channels if given user id" do
          user = Factory :user
          channel = Factory :youtube_channel_with_videos
          user.subscribe channel
          params = { :user_id => user.id }
          get "#{resource_uri}", params
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          returned_channels = body_hash.map {|h| h["youtube_account"]}
          returned_channels.should include channel.serializable_hash
        end
        
        %w[keyword youtube trending default].each do |type|
          it "returns requested channel of type '#{type}'"
        end
      end

      describe "get #{resource_uri}/:id" do
        it "should return 404 if not found" do
          get "#{resource_uri}/#{rand(100)}"
          last_response.status.should == 404
        end

        it "should show channel info if found" do
          channel = Factory :youtube_channel_with_videos
          get "#{resource_uri}/#{channel.id}"
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          body_hash.should == channel.serializable_hash
        end
      end

      describe "post #{resource_uri}/:id" do
        it "should create new channel"
      end

      describe "get #{resource_uri}/:id/videos" do
        it "requires a user_id" do
          channel = Factory :youtube_channel_with_videos
          get "#{resource_uri}/#{channel.id}/videos", {}
          last_response.status.should == 404
        end
        
        it "respects limit params" do
          limit = 3
          channel = Factory :youtube_channel_with_videos
          channel.content_videos.count.should > limit
          params = {:user_id=>(Factory :user).id, :limit=>3}
          get "#{resource_uri}/#{channel.id}/videos", params
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          body_hash.count.should == limit
        end
        
        it "should not returned viewed videos" do
          channel = Factory :youtube_channel_with_videos
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
